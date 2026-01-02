#!/bin/bash

# ==========================================
# XAYZ UNIVERSAL LIBRARY GENERATOR (AUTO-DETECT)
# ==========================================

# Warna
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}   XAYZ YTDL UNIVERSAL - AUTO SETUP & DEPLOY     ${NC}"
echo -e "${CYAN}=================================================${NC}"

# --- 1. SETUP FOLDER ---
PROJECT_NAME="xayz-yt"
echo -e "${BLUE}[INFO] Menyiapkan folder project: ${PROJECT_NAME}...${NC}"

# Hapus folder lama jika ada (untuk fresh install)
if [ -d "$PROJECT_NAME" ]; then
  rm -rf "$PROJECT_NAME"
fi
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

# --- 2. GENERATE FILES ---

echo -e "${BLUE}[INFO] Membuat package.json...${NC}"
cat <<EOF > package.json
{
  "name": "xayz-yt",
  "version": "1.0.0",
  "description": "Universal YouTube Downloader, Search & Play Engine. Supports Node.js (CJS/ESM) and Browser.",
  "main": "./dist/index.js",
  "module": "./dist/index.mjs",
  "types": "./dist/index.d.ts",
  "browser": "./dist/index.global.js",
  "exports": {
    ".": {
      "require": "./dist/index.js",
      "import": "./dist/index.mjs",
      "types": "./dist/index.d.ts"
    }
  },
  "files": [
    "dist"
  ],
  "scripts": {
    "build": "tsup",
    "prepublishOnly": "npm run build",
    "test": "echo 'Error: no test specified' && exit 1"
  },
  "keywords": [
    "youtube",
    "downloader",
    "search",
    "play",
    "music",
    "video",
    "scraper",
    "api",
    "xayz"
  ],
  "author": "XYCoolcraft",
  "license": "ISC",
  "dependencies": {
    "axios": "^1.6.0",
    "yt-search": "^2.10.4"
  },
  "devDependencies": {
    "tsup": "^8.0.1",
    "typescript": "^5.3.3"
  }
}
EOF

echo -e "${BLUE}[INFO] Membuat tsup.config.ts...${NC}"
cat <<EOF > tsup.config.ts
import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/index.ts'],
  format: ['cjs', 'esm', 'iife'],
  dts: true,
  splitting: false,
  sourcemap: true,
  clean: true,
  globalName: 'XayzYouTube',
  minify: true,
  target: 'es2020'
});
EOF

echo -e "${BLUE}[INFO] Membuat tsconfig.json...${NC}"
cat <<EOF > tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "strict": true,
    "skipLibCheck": true
  }
}
EOF

echo -e "${BLUE}[INFO] Menulis Source Code (src/index.ts)...${NC}"
mkdir src
cat <<'EOF' > src/index.ts
import axios from 'axios';
import yts from 'yt-search';

const C = {
    reset: "\x1b[0m",
    green: "\x1b[32m",
    brightGreen: "\x1b[92m",
    cyan: "\x1b[36m",
    yellow: "\x1b[33m",
    magenta: "\x1b[35m",
    red: "\x1b[31m",
    blue: "\x1b[34m",
    white: "\x1b[37m"
};

interface DownloadInfo {
    type: string;
    quality: string;
    format: string;
    url: string;
}

interface VideoData {
    id: string;
    title: string;
    thumbnail: string | undefined;
    duration?: number | string;
    author?: string;
    published?: string;
    description?: string;
    downloads: DownloadInfo[];
}

interface SearchResultItem {
    id: string;
    title: string;
    url: string;
    thumbnail: string;
    duration: string | number;
    author: string;
    published: string;
    description: string;
}

interface XayzResponse {
    status: boolean;
    server?: string;
    message?: string;
    owner?: string;
    data: VideoData | SearchResultItem[] | any;
}

function getVideoId(url: string): string | null {
    const regex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/;
    const match = url.match(regex);
    return match ? match[1] : null;
}

export class XayzYouTube {
    private apiKey: string;
    private invidiousInstances: string[];
    private fallbackUrl: string;

    constructor(apiKey: string) {
        if (!apiKey) {
            throw new Error(`${C.red}[Xayz-YTDL] Error: API Key is required!${C.reset}`);
        }

        this.apiKey = this._cleanApiKey(apiKey);
        
        this._showBanner();

        this.invidiousInstances = [
            "https://inv.tux.pizza",
            "https://vid.puffyan.us",
            "https://yewtu.be",
            "https://invidious.kavin.rocks",
            "https://invidious.drgns.space",
            "https://invidious.lunar.icu",
            "https://yt.artemislena.eu"
        ];
        this.fallbackUrl = "https://api.botcahx.eu.org/api/dowloader/yt";
    }

    private _cleanApiKey(key: string): string {
        return key.trim().replace(/['"]/g, '').replace(/^API_KEY=/, '');
    }

    private _showBanner() {
        const ascii = `
${C.brightGreen}
__  __                  _         _         _   __  _______ 
\\ \\/ / __ _ _   _ ____ / \\  _ __ (_)        \\ \\ / /_   _| 
 \\  / / _\` | | | |_  // _ \\| '_ \\| |         \\ V /  | |   
 /  \\| (_| | |_| |/ // ___ \\ |_) | |          | |   | |   
/_/\\_\\\\__,_|\\__, /___/_/   \\_\\ .__/|_|          |_|   |_|   
            |___/            |_|                            
${C.reset}`;
        
        console.log(ascii);
        console.log(`${C.cyan}=====[ Thank you for using Api Xayz YT ]=====${C.reset}`);
        console.log(`${C.yellow}--> Developer: XYCoolcraft${C.reset}`);
        console.log(`${C.yellow}--> Name 2: Xayz / XY${C.reset}`);
        console.log(`${C.yellow}--> Team: Xayz Tech${C.reset}`);
        console.log(`${C.cyan}=====================================${C.reset}`);
        console.log(`${C.magenta}Using a apikey? Yes, and it's free. Why do you need a key or apikey?${C.reset}`);
        console.log(`${C.magenta}To prevent blacklisting from the CORS system.${C.reset}`);
        console.log(`${C.green}Apikey or key is free and unlimited!${C.reset}`);
        console.log(`${C.blue}Visit and get the apikey on the following website: https://xayz-ytdl.vercel.app${C.reset}`);
        console.log(`${C.green}Apikey withdrawal without any conditions and without ads, Alias free!${C.reset}`);
        console.log(`${C.cyan}=====================================${C.reset}\n`);
    }

    public async search(query: string): Promise<XayzResponse> {
        if (!query) throw new Error("Query is required!");
        try {
            const r = await yts(query);
            return {
                status: true,
                message: "Search Results",
                data: (r.videos || []).map(v => ({
                    id: v.videoId,
                    title: v.title,
                    author: v.author.name,
                    thumbnail: v.thumbnail,
                    url: v.url,
                    duration: v.timestamp,
                    published: v.ago,
                    description: v.description
                }))
            };
        } catch (e: any) {
            throw new Error(`Search Failed: ${e.message}`);
        }
    }

    public async play(query: string): Promise<XayzResponse> {
        if (!query) throw new Error("Query is required!");
        try {
            const searchRes = await this.search(query);
            const videos = searchRes.data as SearchResultItem[];
            
            if (!videos || videos.length === 0) {
                throw new Error("No video results found for play command.");
            }

            const firstVideo = videos[0];
            return await this.download(firstVideo.url);

        } catch (e: any) {
            throw new Error(`Play Engine Failed: ${e.message}`);
        }
    }

    public async download(url: string): Promise<XayzResponse> {
        if (!url) throw new Error("URL is required!");
        const videoId = getVideoId(url);
        if (!videoId) throw new Error("Invalid YouTube URL");

        let success = false;
        let resultData: XayzResponse | null = null;
        let attempt = 0;
        
        const shuffled = this.invidiousInstances.sort(() => 0.5 - Math.random());

        while (attempt < 3 && !success) {
            try {
                const instance = shuffled[attempt];
                attempt++;
                const resp = await axios.get(`${instance}/api/v1/videos/${videoId}`, { timeout: 6000 });
                
                if (resp.status === 200) {
                    const d = resp.data;
                    let downloads: DownloadInfo[] = [];
                    
                    if (d.formatStreams) {
                        d.formatStreams.forEach((v: any) => {
                            downloads.push({ 
                                type: "video", 
                                quality: v.qualityLabel, 
                                format: v.container, 
                                url: v.url 
                            });
                        });
                    }
                    if (d.adaptiveFormats) {
                        const aud = d.adaptiveFormats.find((a: any) => a.type.includes("audio/mp4"));
                        if (aud) {
                            downloads.push({ 
                                type: "audio", 
                                quality: "HQ", 
                                format: "m4a", 
                                url: aud.url 
                            });
                        }
                    }

                    resultData = {
                        status: true,
                        server: "Invidious",
                        owner: "Xayz Tech",
                        data: { 
                            id: videoId, 
                            title: d.title, 
                            thumbnail: d.videoThumbnails?.[0]?.url, 
                            duration: d.lengthSeconds,
                            author: d.author,
                            published: d.publishedText || "",
                            description: d.description || "",
                            downloads 
                        }
                    };
                    success = true;
                }
            } catch (e) { 
                continue; 
            }
        }

        if (!success) {
            try {
                const fbUrl = `${this.fallbackUrl}?url=${encodeURIComponent(url)}&apikey=${this.apiKey}`;
                const fbRes = await axios.get(fbUrl);
                
                if (fbRes.data.status && fbRes.data.result) {
                    const r = fbRes.data.result;
                    resultData = {
                        status: true,
                        server: "XYCoolcraft",
                        owner: "Xayz Tech",
                        data: { 
                            id: r.id, 
                            title: r.title, 
                            thumbnail: r.thumb, 
                            duration: r.duration,
                            author: "External",
                            published: "Unknown",
                            description: "Xayz Api YT Successfull",
                            downloads: [
                                { type: "video", quality: "Auto", format: "mp4", url: r.mp4 },
                                { type: "audio", quality: "Auto", format: "mp3", url: r.mp3 }
                            ]
                        }
                    };
                    success = true;
                }
            } catch (e) { 
                throw new Error("All servers busy. Please check your API Key or try again later."); 
            }
        }

        if (success && resultData) return resultData;
        throw new Error("Failed to fetch data");
    }
}
EOF

echo -e "${BLUE}[INFO] Membuat .gitignore & .npmignore...${NC}"
cat <<EOF > .gitignore
node_modules
dist
.env
.DS_Store
EOF

cat <<EOF > .npmignore
src/
tsup.config.ts
node_modules/
.gitignore
setup.sh
EOF

echo -e "${BLUE}[INFO] Membuat README.md...${NC}"
cat <<EOF > README.md
# Xayz YTDL Universal

Powerful Universal YouTube Downloader, Search Engine & Auto-Play Library.
Compatible with Node.js (CommonJS & ESM), Browser (Vanilla JS), and other environments via API key authentication.

## Features

- 🔍 **Advanced Search**: Fetch detailed metadata (Thumbnail, Author, Date, Duration).
- ⏯️ **Play Engine**: Automatically search and fetch download links for the top result.
- 📥 **Multi-Source Downloader**: Hybrid engine using Invidious Rotation + Botcahx Fallback.
- 🛡️ **CORS Protection**: Built-in API Key validation system.
- 🎨 **RGB Banner**: Signature startup banner for Xayz Tech.
- 🌐 **Universal Build**: Works in NodeJS, React, Vue, Python (via Wrapper), and pure HTML/JS.

## Installation

\`\`\`bash
npm install xayz-yt
\`\`\`

## Usage

### 1. Initialization (Required)

\`\`\`javascript
import { XayzYouTube } from 'xayz-yt';

// Supports various formats:
// const apiKey = "API_KEY=xayztech-123";
// const apiKey = "xayztech-123";
const apiKey = "YOUR_FREE_API_KEY"; 

const yt = new XayzYouTube(apiKey);
\`\`\`

### 2. Search Only (Metadata)

\`\`\`javascript
const results = await yt.search("Alan Walker Faded");
console.log(results.data);
\`\`\`

### 3. Play (Search + Auto Download Top Result)

Perfect for bots or music players.

\`\`\`javascript
try {
    const playResult = await yt.play("smezir_2 slowed");
    console.log("Title:", playResult.data.title);
    console.log("Downloads:", playResult.data.downloads);
} catch (e) {
    console.log(e);
}
\`\`\`

### 4. Download (From URL)

\`\`\`javascript
const result = await yt.download("https://youtu.be/dQw4w9WgXcQ");
console.log(result.data.downloads);
\`\`\`

## API Key

Get your free API Key here: https://xayz-ytdl.vercel.app

## License

ISC
EOF

# --- 3. INSTALL & BUILD ---

echo -e "${GREEN}[ACTION] Menginstall dependencies...${NC}"
npm install

echo -e "${GREEN}[ACTION] Membangun project (Universal Build)...${NC}"
npm run build

# --- 4. GIT AUTO-DETECT & UPLOAD ---

echo -e "${GREEN}[ACTION] Inisialisasi Git...${NC}"
git init
git add .
git commit -m "Initial release of Xayz Universal YTDL"

# DETEKSI URL OTOMATIS
DETECTED_REPO=""

# Cek Environment Variable (Codespaces/Actions)
if [ -n "$GITHUB_REPOSITORY" ]; then
    DETECTED_REPO="https://github.com/${GITHUB_REPOSITORY}.git"
fi

# Cek Git Config (Jika local sudah disetting)
if [ -z "$DETECTED_REPO" ]; then
    EXISTING_REMOTE=$(git remote get-url origin 2>/dev/null)
    if [ -n "$EXISTING_REMOTE" ]; then
        DETECTED_REPO=$EXISTING_REMOTE
    fi
fi

echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}   SETUP SELESAI! KONFIGURASI GITHUB             ${NC}"
echo -e "${CYAN}=================================================${NC}"

if [ -n "$DETECTED_REPO" ]; then
    echo -e "${YELLOW}Ditemukan Repository Otomatis: ${DETECTED_REPO}${NC}"
    echo -e "Apakah kamu ingin menggunakan repo ini? (y/n)"
    read -p "Pilihan (Default y): " auto_choice
    auto_choice=${auto_choice:-y} # Default Yes

    if [[ "$auto_choice" == "y" || "$auto_choice" == "Y" ]]; then
        FINAL_REPO=$DETECTED_REPO
    else
        echo -e "Masukkan URL Repository GitHub manual:"
        read -p "URL Repo: " manual_repo
        FINAL_REPO=$manual_repo
    fi
else
    echo -e "${YELLOW}Repository tidak terdeteksi otomatis.${NC}"
    echo -e "Masukkan URL Repository GitHub kamu (contoh: https://github.com/User/repo.git):"
    read -p "URL Repo: " manual_repo
    FINAL_REPO=$manual_repo
fi

if [ -n "$FINAL_REPO" ]; then
    git branch -M main
    # Hapus remote origin lama jika ada supaya tidak error
    git remote remove origin 2>/dev/null
    git remote add origin "$FINAL_REPO"
    
    echo -e "${GREEN}[ACTION] Mengirim kode ke GitHub ($FINAL_REPO)...${NC}"
    git push -u origin main
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}BERHASIL! Kode sudah online di GitHub.${NC}"
    else
        echo -e "${RED}GAGAL UPLOAD. Pastikan kamu sudah login git atau token valid.${NC}"
    fi
else
    echo -e "${RED}URL kosong. Melewati upload GitHub.${NC}"
fi

echo -e "${CYAN}=================================================${NC}"
echo -e "${GREEN}SIAP UNTUK NPM PUBLISH!${NC}"
echo -e "Jalankan perintah ini:"
echo -e "1. ${YELLOW}cd $PROJECT_NAME${NC}"
echo -e "2. ${YELLOW}npm login${NC}"
echo -e "3. ${YELLOW}npm publish --access public${NC}"
echo -e "${CYAN}=================================================${NC}"
