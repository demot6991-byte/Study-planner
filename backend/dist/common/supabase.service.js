"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SupabaseService = void 0;
const common_1 = require("@nestjs/common");
const supabase_js_1 = require("@supabase/supabase-js");
let SupabaseService = class SupabaseService {
    constructor() {
        this.url = process.env.SUPABASE_URL;
        this.anonKey = process.env.SUPABASE_ANON_KEY;
        if (!this.url || !this.anonKey) {
            throw new Error('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
        }
        this.client = (0, supabase_js_1.createClient)(this.url, this.anonKey, {
            auth: {
                autoRefreshToken: false,
                persistSession: false,
            },
        });
    }
    createUserClient(accessToken) {
        return (0, supabase_js_1.createClient)(this.url, this.anonKey, {
            global: {
                headers: {
                    Authorization: `Bearer ${accessToken}`,
                },
            },
            auth: {
                autoRefreshToken: false,
                persistSession: false,
            },
        });
    }
    async refreshSession(refreshToken) {
        const { data, error } = await this.client.auth.refreshSession({
            refresh_token: refreshToken,
        });
        if (error || !data.session) {
            return null;
        }
        return {
            user: { id: data.user.id, email: data.user.email || '' },
            session: {
                access_token: data.session.access_token,
                refresh_token: data.session.refresh_token,
            },
        };
    }
};
exports.SupabaseService = SupabaseService;
exports.SupabaseService = SupabaseService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [])
], SupabaseService);
//# sourceMappingURL=supabase.service.js.map