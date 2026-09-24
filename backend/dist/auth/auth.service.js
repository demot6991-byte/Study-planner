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
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../common/supabase.service");
const jwt_service_1 = require("../common/jwt.service");
let AuthService = class AuthService {
    constructor(supabaseService, jwtService) {
        this.supabaseService = supabaseService;
        this.jwtService = jwtService;
    }
    async signUp(email, password) {
        if (!email || !password) {
            throw new common_1.BadRequestException('Email and password required');
        }
        const { data, error } = await this.supabaseService.client.auth.signUp({ email, password });
        if (error) {
            throw new common_1.BadRequestException(error.message);
        }
        if (!data.session) {
            return { user: { id: data.user.id, email: data.user.email || '' }, token: null };
        }
        const token = this.jwtService.sign({
            sub: data.user.id,
            email: data.user.email || '',
            supabase_access_token: data.session.access_token,
            supabase_refresh_token: data.session.refresh_token,
        });
        return {
            user: { id: data.user.id, email: data.user.email || '' },
            token,
            session: {
                access_token: data.session.access_token,
                refresh_token: data.session.refresh_token,
            },
        };
    }
    async signIn(email, password) {
        if (!email || !password) {
            throw new common_1.BadRequestException('Email and password required');
        }
        const { data, error } = await this.supabaseService.client.auth.signInWithPassword({ email, password });
        if (error) {
            throw new common_1.BadRequestException(error.message);
        }
        const token = this.jwtService.sign({
            sub: data.user.id,
            email: data.user.email || '',
            supabase_access_token: data.session.access_token,
            supabase_refresh_token: data.session.refresh_token,
        });
        return {
            user: { id: data.user.id, email: data.user.email || '' },
            token,
            session: {
                access_token: data.session.access_token,
                refresh_token: data.session.refresh_token,
            },
        };
    }
    async refreshToken(refreshToken) {
        if (!refreshToken) {
            throw new common_1.BadRequestException('Refresh token required');
        }
        const result = await this.supabaseService.refreshSession(refreshToken);
        if (!result) {
            throw new common_1.UnauthorizedException('Invalid or expired refresh token');
        }
        const token = this.jwtService.sign({
            sub: result.user.id,
            email: result.user.email,
            supabase_access_token: result.session.access_token,
            supabase_refresh_token: result.session.refresh_token,
        });
        return {
            user: result.user,
            token,
            session: result.session,
        };
    }
    async getGoogleUrl() {
        const supabaseUrl = process.env.SUPABASE_URL || '';
        const anonKey = process.env.SUPABASE_ANON_KEY || '';
        const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
        const callbackUrl = `${frontendUrl}/auth/callback`;
        const params = new URLSearchParams({
            client_id: anonKey,
            redirect_uri: `${supabaseUrl}/auth/v1/callback`,
            response_type: 'code',
            scope: 'openid profile email',
            flow: 'code',
            state: callbackUrl,
        });
        return { url: `${supabaseUrl}/auth/v1/authorize?provider=google&${params.toString()}` };
    }
    async exchangeCodeForSession(code) {
        if (!code) {
            throw new common_1.BadRequestException('Authorization code required');
        }
        try {
            const { data, error } = await this.supabaseService.client.auth.exchangeCodeForSession(code);
            if (error || !data.session) {
                throw new common_1.BadRequestException(error?.message || 'Failed to exchange code');
            }
            const token = this.jwtService.sign({
                sub: data.user.id,
                email: data.user.email || '',
                supabase_access_token: data.session.access_token,
                supabase_refresh_token: data.session.refresh_token,
            });
            return {
                user: { id: data.user.id, email: data.user.email || '' },
                token,
                session: {
                    access_token: data.session.access_token,
                    refresh_token: data.session.refresh_token,
                },
            };
        }
        catch (err) {
            if (err instanceof common_1.BadRequestException)
                throw err;
            throw new common_1.BadRequestException(err.message || 'Exchange failed');
        }
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService,
        jwt_service_1.JwtService])
], AuthService);
//# sourceMappingURL=auth.service.js.map