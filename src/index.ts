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
