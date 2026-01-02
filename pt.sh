#!/bin/bash

# Konfigurasi Warna (Simulasi RGB)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Direktori Pterodactyl
PTERO_DIR="/var/www/pterodactyl"
BACKUP_ROOT="/root/XYCool_Backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
CURRENT_BACKUP_DIR="$BACKUP_ROOT/backup_$TIMESTAMP"

# Daftar File Target (Sesuai permintaan mbut.sh s/d mbut11.sh, KECUALI mbut12.sh)
FILES=(
    "resources/views/templates/base/core.blade.php"                 # mbut10 (Welcome Msg)
    "app/Http/Controllers/Admin/NodesController.php"                # mbut11 (Anti Update Nodes)
    "app/Http/Controllers/Admin/Settings/IndexController.php"       # mbut6 (Anti Settings)
    "app/Http/Controllers/Admin/Nests/NestController.php"           # mbut5 (Anti Nest)
    "app/Http/Controllers/Admin/Nodes/NodeController.php"           # mbut4 (Anti Access Nodes View)
    "app/Http/Controllers/Api/Client/Servers/FileController.php"    # mbut7 (Anti File Manager)
    "app/Http/Controllers/Admin/LocationController.php"             # mbut3 (Anti Location)
    "app/Http/Controllers/Admin/UserController.php"                 # mbut2 (Anti User Edit/Del)
    "app/Services/Servers/ServerDeletionService.php"                # mbut (Anti Del Server)
    "app/Http/Controllers/Api/Client/Servers/ServerController.php"  # mbut8 (Anti Server Controller)
    "app/Services/Servers/DetailsModificationService.php"           # mbut9 (Anti Modify Server)
)

# Fungsi Banner RGB
show_banner() {
    clear
    echo -e "${RED}========[ ${YELLOW}Thank you for using the Pterodactyl Panel Protection ${CYAN}made by XYCoolcraft ${RED}]======${RESET}"
    echo -e "${GREEN}-> 1 ${CYAN}Pasang Proteksi${RESET}"
    echo -e "${GREEN}-> 2 ${CYAN}Membuat Backup${RESET}"
    echo -e "${GREEN}-> 3 ${CYAN}Restore/Melepas Proteksi Panel Pterodactyl${RESET}"
    echo -e "${RED}==========================================================================================${RESET}"
}

# Fungsi Backup
create_backup() {
    echo -e "\n${YELLOW}📦 Sedang membuat backup file original...${RESET}"
    mkdir -p "$CURRENT_BACKUP_DIR"

    for file in "${FILES[@]}"; do
        FULL_PATH="$PTERO_DIR/$file"
        if [ -f "$FULL_PATH" ]; then
            # Copy dengan struktur folder parent agar mudah restore
            cp --parents "$FULL_PATH" "$CURRENT_BACKUP_DIR/" 2>/dev/null
            # cp "$FULL_PATH" "$CURRENT_BACKUP_DIR/$(basename "$file")"
            echo -e "${CYAN}   - Backed up: $file${RESET}"
        else
            echo -e "${RED}   ! File tidak ditemukan (dilewati): $file${RESET}"
        fi
    done
    
    # Backup file zip agar mudah didownload user jika mau
    cd "$BACKUP_ROOT" || exit
    zip -r -q "backup_$TIMESTAMP.zip" "backup_$TIMESTAMP"
    
    echo -e "${GREEN}✅ Backup selesai! Disimpan di: $CURRENT_BACKUP_DIR${RESET}"
    echo -e "${GREEN}🗄️  File Zip juga tersedia di: $BACKUP_ROOT/backup_$TIMESTAMP.zip${RESET}"
    sleep 2
}

# Fungsi Clear Cache
clear_cache() {
    echo -e "\n${MAGENTA}🧹 Membersihkan Cache & Reload System...${RESET}"
    cd "$PTERO_DIR" || exit
    
    echo -e "${CYAN}-> php artisan view:clear${RESET}"
    php artisan view:clear
    
    echo -e "${CYAN}-> php artisan config:clear${RESET}"
    php artisan config:clear
    
    echo -e "${CYAN}-> php artisan route:clear${RESET}"
    php artisan route:clear
    
    # Restart Queue worker untuk menerapkan perubahan di backend
    echo -e "${CYAN}-> Restarting Queue Worker...${RESET}"
    php artisan queue:restart

    echo -e "${GREEN}✅ System Refreshed!${RESET}"
}

# Fungsi Install Proteksi
install_protection() {
    # Langkah 1: Backup Dulu
    create_backup

    echo -e "\n${YELLOW}🚀 Memulai Pemasangan Proteksi...${RESET}"
    sleep 1

    # --- 1. Base Core Blade (Welcome Message) ---
    cat > "$PTERO_DIR/resources/views/templates/base/core.blade.php" << 'EOF'
@extends('templates/wrapper', [
    'css' => ['body' => 'bg-neutral-800'],
])

@section('container')
    <div id="modal-portal"></div>
    <div id="app"></div>

    <script>
      document.addEventListener("DOMContentLoaded", () => {
        const username = @json(auth()->user()->name?? 'User');

        const message = document.createElement("div");
        message.innerText = `👋 Hai ${username}, Apa kabar🤓? ~Xayz`;
        Object.assign(message.style, {
          position: "fixed",
          bottom: "20px",
          right: "20px",
          background: "rgba(0,0,0,0.75)",
          color: "#fff",
          padding: "10px 15px",
          borderRadius: "10px",
          fontFamily: "monospace",
          fontSize: "14px",
          boxShadow: "0 0 10px rgba(0,0,0,0.3)",
          zIndex: "9999",
          opacity: "1",
          transition: "opacity 1s ease"
        });

        document.body.appendChild(message);
        setTimeout(() => message.style.opacity = "0", 3000);
        setTimeout(() => message.remove(), 4000);
      });
    </script>
@endsection
EOF
    echo -e "${GREEN}   -> Core Blade Updated${RESET}"

    # --- 2. NodesController (Anti Update Nodes) ---
    cat > "$PTERO_DIR/app/Http/Controllers/Admin/NodesController.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Models\Node;
use Pterodactyl\Models\Allocation;
use Pterodactyl\Http\Controllers\Controller;
use Prologue\Alerts\AlertsMessageBag;
use Pterodactyl\Services\Nodes\NodeUpdateService;
use Pterodactyl\Services\Nodes\NodeCreationService;
use Pterodactyl\Services\Nodes\NodeDeletionService;
use Pterodactyl\Services\Allocations\AssignmentService;
use Pterodactyl\Services\Allocations\AllocationDeletionService;
use Pterodactyl\Contracts\Repository\NodeRepositoryInterface;
use Pterodactyl\Contracts\Repository\ServerRepositoryInterface;
use Pterodactyl\Contracts\Repository\LocationRepositoryInterface;
use Pterodactyl\Contracts\Repository\AllocationRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Node\NodeFormRequest;
use Pterodactyl\Http\Requests\Admin\Node\AllocationFormRequest;
use Pterodactyl\Http\Requests\Admin\Node\AllocationAliasFormRequest;
use Pterodactyl\Services\Helpers\SoftwareVersionService;

class NodesController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected AllocationDeletionService $allocationDeletionService,
        protected AllocationRepositoryInterface $allocationRepository,
        protected AssignmentService $assignmentService,
        protected NodeCreationService $creationService,
        protected NodeDeletionService $deletionService,
        protected LocationRepositoryInterface $locationRepository,
        protected NodeRepositoryInterface $repository,
        protected ServerRepositoryInterface $serverRepository,
        protected NodeUpdateService $updateService,
        protected SoftwareVersionService $versionService,
        protected ViewFactory $view
    ) {}

    public function create(): View|RedirectResponse
    {
        $locations = $this->locationRepository->all();
        if (count($locations) < 1) {
            $this->alert->warning(trans('admin/node.notices.location_required'))->flash();
            return redirect()->route('admin.locations');
        }

        return $this->view->make('admin.nodes.new', ['locations' => $locations]);
    }

    public function store(NodeFormRequest $request): RedirectResponse
    {
        $user = auth()->user();
        if ($user->id !== 1) {
            abort(403, "🚫 Kamu tidak punya izin untuk menambahkan node. Hanya admin ID 1 yang bisa!");
        }

        $node = $this->creationService->handle($request->normalize());
        $this->alert->info(trans('admin/node.notices.node_created'))->flash();
        return redirect()->route('admin.nodes.view.allocation', $node->id);
    }

    public function updateSettings(NodeFormRequest $request, Node $node): RedirectResponse
    {
        $user = auth()->user();
        if ($user->id !== 1) {
            abort(403, "⚠️ AKSES DI TOLAK HANYA ADMIN ID 1 YANG BISA EDIT NODE");
        }

        $this->updateService->handle($node, $request->normalize(), $request->input('reset_secret') === 'on');
        $this->alert->success(trans('admin/node.notices.node_updated'))->flash();
        return redirect()->route('admin.nodes.view.settings', $node->id)->withInput();
    }

    public function delete(int|Node $node): RedirectResponse
    {
        $user = auth()->user();
        if ($user->id !== 1) {
            abort(403, "❌ Lu sehat melakukan hapus node? ~Xayz");
        }

        $this->deletionService->handle($node);
        $this->alert->success(trans('admin/node.notices.node_deleted'))->flash();
        return redirect()->route('admin.nodes');
    }
}
EOF
    echo -e "${GREEN}   -> NodesController Updated${RESET}"

    # --- 3. Settings/IndexController (Anti Access Settings) ---
    cat > "$PTERO_DIR/app/Http/Controllers/Admin/Settings/IndexController.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin\Settings;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Traits\Helpers\AvailableLanguages;
use Pterodactyl\Services\Helpers\SoftwareVersionService;
use Pterodactyl\Contracts\Repository\SettingsRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Settings\BaseSettingsFormRequest;

class IndexController extends Controller
{
    use AvailableLanguages;

    public function __construct(
        private AlertsMessageBag $alert,
        private Kernel $kernel,
        private SettingsRepositoryInterface $settings,
        private SoftwareVersionService $versionService,
        private ViewFactory $view
    ) {
    }

    public function index(): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Ngapain Ngintip bang? ~Xayz');
        }

        return $this->view->make('admin.settings.index', [
            'version' => $this->versionService,
            'languages' => $this->getAvailableLanguages(true),
        ]);
    }

    public function update(BaseSettingsFormRequest $request): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Ngapain Ngintip bang? ~Xayz');
        }

        foreach ($request->normalize() as $key => $value) {
            $this->settings->set('settings::' . $key, $value);
        }

        $this->kernel->call('queue:restart');
        $this->alert->success(
            'Panel settings have been updated successfully and the queue worker was restarted to apply these changes.'
        )->flash();

        return redirect()->route('admin.settings');
    }
}
EOF
    echo -e "${GREEN}   -> Settings/IndexController Updated${RESET}"

    # --- 4. NestController (Anti Nest) ---
    cat > "$PTERO_DIR/app/Http/Controllers/Admin/Nests/NestController.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin\Nests;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Services\Nests\NestUpdateService;
use Pterodactyl\Services\Nests\NestCreationService;
use Pterodactyl\Services\Nests\NestDeletionService;
use Pterodactyl\Contracts\Repository\NestRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Nest\StoreNestFormRequest;
use Illuminate\Support\Facades\Auth;

class NestController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected NestCreationService $nestCreationService,
        protected NestDeletionService $nestDeletionService,
        protected NestRepositoryInterface $repository,
        protected NestUpdateService $nestUpdateService,
        protected ViewFactory $view
    ) {
    }

    public function index(): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, '🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa membuka menu Nests.');
        }

        return $this->view->make('admin.nests.index', [
            'nests' => $this->repository->getWithCounts(),
        ]);
    }

    public function create(): View
    {
        return $this->view->make('admin.nests.new');
    }

    public function store(StoreNestFormRequest $request): RedirectResponse
    {
        $nest = $this->nestCreationService->handle($request->normalize());
        $this->alert->success(trans('admin/nests.notices.created', ['name' => htmlspecialchars($nest->name)]))->flash();

        return redirect()->route('admin.nests.view', $nest->id);
    }

    public function view(int $nest): View
    {
        return $this->view->make('admin.nests.view', [
            'nest' => $this->repository->getWithEggServers($nest),
        ]);
    }

    public function update(StoreNestFormRequest $request, int $nest): RedirectResponse
    {
        $this->nestUpdateService->handle($nest, $request->normalize());
        $this->alert->success(trans('admin/nests.notices.updated'))->flash();

        return redirect()->route('admin.nests.view', $nest);
    }

    public function destroy(int $nest): RedirectResponse
    {
        $this->nestDeletionService->handle($nest);
        $this->alert->success(trans('admin/nests.notices.deleted'))->flash();

        return redirect()->route('admin.nests');
    }
}
EOF
    echo -e "${GREEN}   -> NestController Updated${RESET}"

    # --- 5. Nodes/NodeController (Anti Access Nodes) ---
    cat > "$PTERO_DIR/app/Http/Controllers/Admin/Nodes/NodeController.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin\Nodes;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\Node;
use Spatie\QueryBuilder\QueryBuilder;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\View\Factory as ViewFactory;
use Illuminate\Support\Facades\Auth;

class NodeController extends Controller
{
    public function __construct(private ViewFactory $view)
    {
    }

    public function index(Request $request): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, '🚫 Akses ditolak! Hanya admin ID 1 yang dapat membuka menu Nodes.');
        }

        $nodes = QueryBuilder::for(
            Node::query()->with('location')->withCount('servers')
        )
            ->allowedFilters(['uuid', 'name'])
            ->allowedSorts(['id'])
            ->paginate(25);

        return $this->view->make('admin.nodes.index', ['nodes' => $nodes]);
    }
}
EOF
    echo -e "${GREEN}   -> Nodes/NodeController Updated${RESET}"

    # --- 6. FileController (Anti File Manager) ---
    cat > "$PTERO_DIR/app/Http/Controllers/Api/Client/Servers/FileController.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Api\Client\Servers;

use Carbon\CarbonImmutable;
use Illuminate\Http\Response;
use Illuminate\Http\JsonResponse;
use Pterodactyl\Models\Server;
use Pterodactyl\Facades\Activity;
use Pterodactyl\Services\Nodes\NodeJWTService;
use Pterodactyl\Repositories\Wings\DaemonFileRepository;
use Pterodactyl\Transformers\Api\Client\FileObjectTransformer;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\CopyFileRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\PullFileRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\ListFilesRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\ChmodFilesRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\DeleteFileRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\RenameFileRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\CreateFolderRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\CompressFilesRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\DecompressFilesRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\GetFileContentsRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\WriteFileContentRequest;

class FileController extends ClientApiController
{
    public function __construct(
        private NodeJWTService $jwtService,
        private DaemonFileRepository $fileRepository
    ) {
        parent::__construct();
    }

    private function checkServerAccess($request, Server $server)
    {
        $user = $request->user();
        if ($user->id === 1) {
            return;
        }
        if ($server->owner_id !== $user->id) {
            abort(403, 'Anda tidak memiliki akses ke server ini.');
        }
    }

    public function directory(ListFilesRequest $request, Server $server): array
    {
        $this->checkServerAccess($request, $server);
        $contents = $this->fileRepository
            ->setServer($server)
            ->getDirectory($request->get('directory') ?? '/');
        return $this->fractal->collection($contents)
            ->transformWith($this->getTransformer(FileObjectTransformer::class))
            ->toArray();
    }

    public function contents(GetFileContentsRequest $request, Server $server): Response
    {
        $this->checkServerAccess($request, $server);
        $response = $this->fileRepository->setServer($server)->getContent(
            $request->get('file'),
            config('pterodactyl.files.max_edit_size')
        );
        Activity::event('server:file.read')->property('file', $request->get('file'))->log();
        return new Response($response, Response::HTTP_OK, ['Content-Type' => 'text/plain']);
    }

    public function download(GetFileContentsRequest $request, Server $server): array
    {
        $this->checkServerAccess($request, $server);
        $token = $this->jwtService
            ->setExpiresAt(CarbonImmutable::now()->addMinutes(15))
            ->setUser($request->user())
            ->setClaims([
                'file_path' => rawurldecode($request->get('file')),
                'server_uuid' => $server->uuid,
            ])
            ->handle($server->node, $request->user()->id . $server->uuid);
        Activity::event('server:file.download')->property('file', $request->get('file'))->log();
        return [
            'object' => 'signed_url',
            'attributes' => [
                'url' => sprintf(
                    '%s/download/file?token=%s',
                    $server->node->getConnectionAddress(),
                    $token->toString()
                ),
            ],
        ];
    }

    public function write(WriteFileContentRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($request, $server);
        $this->fileRepository->setServer($server)->putContent($request->get('file'), $request->getContent());
        Activity::event('server:file.write')->property('file', $request->get('file'))->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function create(CreateFolderRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($request, $server);
        $this->fileRepository
            ->setServer($server)
            ->createDirectory($request->input('name'), $request->input('root', '/'));
        Activity::event('server:file.create-directory')
            ->property('name', $request->input('name'))
            ->property('directory', $request->input('root'))
            ->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function rename(RenameFileRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($request, $server);
        $this->fileRepository
            ->setServer($server)
            ->renameFiles($request->input('root'), $request->input('files'));
        Activity::event('server:file.rename')
            ->property('directory', $request->input('root'))
            ->property('files', $request->input('files'))
            ->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function copy(CopyFileRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($request, $server);
        $this->fileRepository
            ->setServer($server)
            ->copyFile($request->input('location'));
        Activity::event('server:file.copy')->property('file', $request->input('location'))->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function compress(CompressFilesRequest $request, Server $server): array
    {
        $this->checkServerAccess($request, $server);
        $file = $this->fileRepository->setServer($server)->compressFiles(
            $request->input('root'),
            $request->input('files')
        );
        Activity::event('server:file.compress')
            ->property('directory', $request->input('root'))
            ->property('files', $request->input('files'))
            ->log();
        return $this->fractal->item($file)
            ->transformWith($this->getTransformer(FileObjectTransformer::class))
            ->toArray();
    }

    public function decompress(DecompressFilesRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($request, $server);
        set_time_limit(300);
        $this->fileRepository->setServer($server)->decompressFile(
            $request->input('root'),
            $request->input('file')
        );
        Activity::event('server:file.decompress')
            ->property('directory', $request->input('root'))
            ->property('files', $request->input('file'))
            ->log();
        return new JsonResponse([], JsonResponse::HTTP_NO_CONTENT);
    }

    public function delete(DeleteFileRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($request, $server);
        $this->fileRepository->setServer($server)->deleteFiles(
            $request->input('root'),
            $request->input('files')
        );
        Activity::event('server:file.delete')
            ->property('directory', $request->input('root'))
            ->property('files', $request->input('files'))
            ->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function chmod(ChmodFilesRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($request, $server);
        $this->fileRepository->setServer($server)->chmodFiles(
            $request->input('root'),
            $request->input('files')
        );
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function pull(PullFileRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($request, $server);
        $this->fileRepository->setServer($server)->pull(
            $request->input('url'),
            $request->input('directory'),
            $request->safe(['filename', 'use_header', 'foreground'])
        );
        Activity::event('server:file.pull')
            ->property('directory', $request->input('directory'))
            ->property('url', $request->input('url'))
            ->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }
}
EOF
    echo -e "${GREEN}   -> FileController Updated${RESET}"

    # --- 7. LocationController (Anti Location) ---
    cat > "$PTERO_DIR/app/Http/Controllers/Admin/LocationController.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Location;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Http\Requests\Admin\LocationFormRequest;
use Pterodactyl\Services\Locations\LocationUpdateService;
use Pterodactyl\Services\Locations\LocationCreationService;
use Pterodactyl\Services\Locations\LocationDeletionService;
use Pterodactyl\Contracts\Repository\LocationRepositoryInterface;

class LocationController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected LocationCreationService $creationService,
        protected LocationDeletionService $deletionService,
        protected LocationRepositoryInterface $repository,
        protected LocationUpdateService $updateService,
        protected ViewFactory $view
    ) {
    }

    public function index(): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Akses ditolak');
        }

        return $this->view->make('admin.locations.index', [
            'locations' => $this->repository->getAllWithDetails(),
        ]);
    }

    public function view(int $id): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Ngapain Ngintip bang? ~Xayz ');
        }

        return $this->view->make('admin.locations.view', [
            'location' => $this->repository->getWithNodes($id),
        ]);
    }

    public function create(LocationFormRequest $request): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Ngapain Ngintip bang? ~Xayz ');
        }

        $location = $this->creationService->handle($request->normalize());
        $this->alert->success('Location was created successfully.')->flash();

        return redirect()->route('admin.locations.view', $location->id);
    }

    public function update(LocationFormRequest $request, Location $location): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Ngapain Ngintip bang? ~Xayz ');
        }

        if ($request->input('action') === 'delete') {
            return $this->delete($location);
        }

        $this->updateService->handle($location->id, $request->normalize());
        $this->alert->success('Location was updated successfully.')->flash();

        return redirect()->route('admin.locations.view', $location->id);
    }

    public function delete(Location $location): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Ngapain Ngintip bang? ~Xayz ');
        }

        try {
            $this->deletionService->handle($location->id);
            return redirect()->route('admin.locations');
        } catch (DisplayException $ex) {
            $this->alert->danger($ex->getMessage())->flash();
        }

        return redirect()->route('admin.locations.view', $location->id);
    }
}
EOF
    echo -e "${GREEN}   -> LocationController Updated${RESET}"

    # --- 8. UserController (Anti Hapus/Ubah User) ---
    cat > "$PTERO_DIR/app/Http/Controllers/Admin/UserController.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\User;
use Pterodactyl\Models\Model;
use Illuminate\Support\Collection;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Spatie\QueryBuilder\QueryBuilder;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\Translation\Translator;
use Pterodactyl\Services\Users\UserUpdateService;
use Pterodactyl\Traits\Helpers\AvailableLanguages;
use Pterodactyl\Services\Users\UserCreationService;
use Pterodactyl\Services\Users\UserDeletionService;
use Pterodactyl\Http\Requests\Admin\UserFormRequest;
use Pterodactyl\Http\Requests\Admin\NewUserFormRequest;
use Pterodactyl\Contracts\Repository\UserRepositoryInterface;
class UserController extends Controller
{
    use AvailableLanguages;

    public function __construct(
        protected AlertsMessageBag $alert,
        protected UserCreationService $creationService,
        protected UserDeletionService $deletionService,
        protected Translator $translator,
        protected UserUpdateService $updateService,
        protected UserRepositoryInterface $repository,
        protected ViewFactory $view
    ) {
    }

    public function index(Request $request): View
    {
        $users = QueryBuilder::for(
            User::query()->select('users.*')
                ->selectRaw('COUNT(DISTINCT(subusers.id)) as subuser_of_count')
                ->selectRaw('COUNT(DISTINCT(servers.id)) as servers_count')
                ->leftJoin('subusers', 'subusers.user_id', '=', 'users.id')
                ->leftJoin('servers', 'servers.owner_id', '=', 'users.id')
                ->groupBy('users.id')
        )
            ->allowedFilters(['username', 'email', 'uuid'])
            ->allowedSorts(['id', 'uuid'])
            ->paginate(50);

        return $this->view->make('admin.users.index', ['users' => $users]);
    }

    public function create(): View
    {
        return $this->view->make('admin.users.new', [
            'languages' => $this->getAvailableLanguages(true),
        ]);
    }

    public function view(User $user): View
    {
        return $this->view->make('admin.users.view', [
            'user' => $user,
            'languages' => $this->getAvailableLanguages(true),
        ]);
    }

    public function delete(Request $request, User $user): RedirectResponse
    {
        if ($request->user()->id !== 1) {
            throw new DisplayException("❌ Hanya admin ID 1 yang dapat menghapus user lain!");
        }

        if ($request->user()->id === $user->id) {
            throw new DisplayException($this->translator->get('admin/user.exceptions.user_has_servers'));
        }

        $this->deletionService->handle($user);

        return redirect()->route('admin.users');
    }

    public function store(NewUserFormRequest $request): RedirectResponse
    {
        $user = $this->creationService->handle($request->normalize());
        $this->alert->success($this->translator->get('admin/user.notices.account_created'))->flash();

        return redirect()->route('admin.users.view', $user->id);
    }

    public function update(UserFormRequest $request, User $user): RedirectResponse
    {
        $restrictedFields = ['email', 'first_name', 'last_name', 'password'];

        foreach ($restrictedFields as $field) {
            if ($request->filled($field) && $request->user()->id !== 1) {
                throw new DisplayException("⚠️ Data hanya bisa diubah oleh admin ID 1.");
            }
        }

        if ($user->root_admin && $request->user()->id !== 1) {
            throw new DisplayException("🚫 Tidak dapat menurunkan hak admin pengguna ini. Hanya ID 1 yang memiliki izin.");
        }

        $this->updateService
            ->setUserLevel(User::USER_LEVEL_ADMIN)
            ->handle($user, $request->normalize());

        $this->alert->success(trans('admin/user.notices.account_updated'))->flash();

        return redirect()->route('admin.users.view', $user->id);
    }

    public function json(Request $request): Model|Collection
    {
        $users = QueryBuilder::for(User::query())->allowedFilters(['email'])->paginate(25);

        if ($request->query('user_id')) {
            $user = User::query()->findOrFail($request->input('user_id'));
            $user->md5 = md5(strtolower($user->email));

            return $user;
        }

        return $users->map(function ($item) {
            $item->md5 = md5(strtolower($item->email));

            return $item;
        });
    }
}
EOF
    echo -e "${GREEN}   -> UserController Updated${RESET}"

    # --- 9. ServerDeletionService (Anti Delete Server) ---
    cat > "$PTERO_DIR/app/Services/Servers/ServerDeletionService.php" << 'EOF'
<?php

namespace Pterodactyl\Services\Servers;

use Illuminate\Support\Facades\Auth;
use Pterodactyl\Exceptions\DisplayException;
use Illuminate\Http\Response;
use Pterodactyl\Models\Server;
use Illuminate\Support\Facades\Log;
use Illuminate\Database\ConnectionInterface;
use Pterodactyl\Repositories\Wings\DaemonServerRepository;
use Pterodactyl\Services\Databases\DatabaseManagementService;
use Pterodactyl\Exceptions\Http\Connection\DaemonConnectionException;

class ServerDeletionService
{
    protected bool $force = false;

    public function __construct(
        private ConnectionInterface $connection,
        private DaemonServerRepository $daemonServerRepository,
        private DatabaseManagementService $databaseManagementService
    ) {
    }

    public function withForce(bool $bool = true): self
    {
        $this->force = $bool;
        return $this;
    }

    public function handle(Server $server): void
    {
        $user = Auth::user();
        if ($user) {
            if ($user->id !== 1) {
                $ownerId = $server->owner_id
                    ?? $server->user_id
                    ?? ($server->owner?->id ?? null)
                    ?? ($server->user?->id ?? null);

                if ($ownerId === null) {
                    throw new DisplayException('Akses ditolak: informasi pemilik server tidak tersedia.');
                }

                if ($ownerId !== $user->id) {
                    throw new DisplayException('❌Akses ditolak: Anda hanya dapat menghapus server milik Anda sendiri');
                }
            }
        }

        try {
            $this->daemonServerRepository->setServer($server)->delete();
        } catch (DaemonConnectionException $exception) {
            if (!$this->force && $exception->getStatusCode() !== Response::HTTP_NOT_FOUND) {
                throw $exception;
            }
            Log::warning($exception);
        }

        $this->connection->transaction(function () use ($server) {
            foreach ($server->databases as $database) {
                try {
                    $this->databaseManagementService->delete($database);
                } catch (\Exception $exception) {
                    if (!$this->force) {
                        throw $exception;
                    }
                    $database->delete();
                    Log::warning($exception);
                }
            }

            $server->delete();
        });
    }
}
EOF
    echo -e "${GREEN}   -> ServerDeletionService Updated${RESET}"

    # --- 10. Client/ServerController (Anti Access Server Controller) ---
    cat > "$PTERO_DIR/app/Http/Controllers/Api/Client/Servers/ServerController.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Api\Client\Servers;

use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Server;
use Pterodactyl\Transformers\Api\Client\ServerTransformer;
use Pterodactyl\Services\Servers\GetUserPermissionsService;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Http\Requests\Api\Client\Servers\GetServerRequest;

class ServerController extends ClientApiController
{
    public function __construct(private GetUserPermissionsService $permissionsService)
    {
        parent::__construct();
    }

    public function index(GetServerRequest $request, Server $server): array
    {
        $authUser = Auth::user();

        if ($authUser->id !== 1 && (int) $server->owner_id !== (int) $authUser->id) {
            abort(403, 'Akses❌. Hanya bisa melihat server sendiri.');
        }

        return $this->fractal->item($server)
            ->transformWith($this->getTransformer(ServerTransformer::class))
            ->addMeta([
                'is_server_owner' => $request->user()->id === $server->owner_id,
                'user_permissions' => $this->permissionsService->handle($server, $request->user()),
            ])
            ->toArray();
    }
}
EOF
    echo -e "${GREEN}   -> Client/ServerController Updated${RESET}"

    # --- 11. DetailsModificationService (Anti Modify Server) ---
    cat > "$PTERO_DIR/app/Services/Servers/DetailsModificationService.php" << 'EOF'
<?php

namespace Pterodactyl\Services\Servers;

use Illuminate\Support\Arr;
use Pterodactyl\Models\Server;
use Illuminate\Support\Facades\Auth;
use Illuminate\Database\ConnectionInterface;
use Pterodactyl\Traits\Services\ReturnsUpdatedModels;
use Pterodactyl\Repositories\Wings\DaemonServerRepository;
use Pterodactyl\Exceptions\Http\Connection\DaemonConnectionException;

class DetailsModificationService
{
    use ReturnsUpdatedModels;

    public function __construct(
        private ConnectionInterface $connection,
        private DaemonServerRepository $serverRepository
    ) {}

    public function handle(Server $server, array $data): Server
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Akses ditolak: hanya admin utama yang bisa mengubah detail server.');
        }

        return $this->connection->transaction(function () use ($data, $server) {
            $owner = $server->owner_id;

            $server->forceFill([
                'external_id' => Arr::get($data, 'external_id'),
                'owner_id' => Arr::get($data, 'owner_id'),
                'name' => Arr::get($data, 'name'),
                'description' => Arr::get($data, 'description') ?? '',
            ])->saveOrFail();

            if ($server->owner_id !== $owner) {
                try {
                    $this->serverRepository->setServer($server)->revokeUserJTI($owner);
                } catch (DaemonConnectionException $exception) {
                }
            }

            return $server;
        });
    }
}
EOF
    echo -e "${GREEN}   -> DetailsModificationService Updated${RESET}"

    # Set Permission
    chmod 755 -R "$PTERO_DIR/app"
    chmod 755 -R "$PTERO_DIR/resources"
    chown -R www-data:www-data "$PTERO_DIR"

    # Bersihkan Cache
    clear_cache
    
    echo -e "\n${GREEN}🔥 SEMUA PROTEKSI BERHASIL DIPASANG! 🔥${RESET}"
}

# Fungsi Restore
restore_protection() {
    echo -e "\n${YELLOW}🔄 Memulai Proses Restore...${RESET}"
    
    # Cari backup terbaru
    LAST_BACKUP=$(ls -td "$BACKUP_ROOT"/backup_* 2>/dev/null | head -1)
    
    if [ -z "$LAST_BACKUP" ]; then
        echo -e "${RED}❌ Tidak ada backup ditemukan di $BACKUP_ROOT${RESET}"
        return
    fi
    
    echo -e "${CYAN}📂 Menggunakan backup terakhir: $LAST_BACKUP${RESET}"
    echo -e "${YELLOW}⚠️  Ini akan menimpa file proteksi dengan file asli dari backup.${RESET}"
    read -p "Lanjutkan? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo -e "${RED}Dibatalkan.${RESET}"
        return
    fi

    # Copy isi folder backup (var/www/pterodactyl/...) kembali ke root /
    # Karena kita backup pakai --parents relative ke root atau full path, kita sesuaikan copy nya
    
    cp -r "$LAST_BACKUP/var/www/pterodactyl/." "$PTERO_DIR/"
    
    echo -e "${GREEN}✅ File berhasil dikembalikan!${RESET}"
    
    # Bersihkan Cache
    clear_cache
}

# Main Loop
while true; do
    show_banner
    echo -e "${MAGENTA}==> Please Select (from 1 and 3):${RESET}"
    read -r choice

    case $choice in
        1)
            install_protection
            echo -e "\n${YELLOW}Tekan Enter untuk kembali ke menu...${RESET}"
            read
            ;;
        2)
            create_backup
            echo -e "\n${YELLOW}Tekan Enter untuk kembali ke menu...${RESET}"
            read
            ;;
        3)
            restore_protection
            echo -e "\n${YELLOW}Tekan Enter untuk kembali ke menu...${RESET}"
            read
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${RESET}"
            sleep 1
            ;;
    esac
done
