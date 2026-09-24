"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const auth_module_1 = require("./auth/auth.module");
const data_module_1 = require("./data/data.module");
const crud_module_1 = require("./crud/crud.module");
const seed_module_1 = require("./seed/seed.module");
const auth_middleware_1 = require("./common/auth.middleware");
const jwt_service_1 = require("./common/jwt.service");
const supabase_service_1 = require("./common/supabase.service");
const health_controller_1 = require("./common/health.controller");
let AppModule = class AppModule {
    configure(consumer) {
        consumer
            .apply(auth_middleware_1.AuthMiddleware)
            .exclude({ path: 'auth/signup', method: common_1.RequestMethod.POST }, { path: 'auth/signin', method: common_1.RequestMethod.POST }, { path: 'auth/signout', method: common_1.RequestMethod.POST }, { path: 'auth/refresh', method: common_1.RequestMethod.POST }, { path: 'auth/google-url', method: common_1.RequestMethod.GET }, { path: 'auth/google/callback', method: common_1.RequestMethod.POST }, { path: 'auth/session', method: common_1.RequestMethod.GET }, { path: 'health', method: common_1.RequestMethod.GET })
            .forRoutes('data', 'seed', 'auth/onboarding', ':table');
    }
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [auth_module_1.AuthModule, data_module_1.DataModule, crud_module_1.CrudModule, seed_module_1.SeedModule],
        controllers: [health_controller_1.HealthController],
        providers: [jwt_service_1.JwtService, supabase_service_1.SupabaseService],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map