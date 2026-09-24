"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthModule = void 0;
const common_1 = require("@nestjs/common");
const auth_controller_1 = require("./auth.controller");
const auth_service_1 = require("./auth.service");
const supabase_service_1 = require("../common/supabase.service");
const jwt_service_1 = require("../common/jwt.service");
const onboarding_controller_1 = require("./onboarding.controller");
const onboarding_service_1 = require("./onboarding.service");
let AuthModule = class AuthModule {
};
exports.AuthModule = AuthModule;
exports.AuthModule = AuthModule = __decorate([
    (0, common_1.Module)({
        controllers: [auth_controller_1.AuthController, onboarding_controller_1.OnboardingController],
        providers: [auth_service_1.AuthService, onboarding_service_1.OnboardingService, supabase_service_1.SupabaseService, jwt_service_1.JwtService],
        exports: [supabase_service_1.SupabaseService, jwt_service_1.JwtService],
    })
], AuthModule);
//# sourceMappingURL=auth.module.js.map