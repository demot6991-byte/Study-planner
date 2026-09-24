"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OnboardingService = void 0;
const common_1 = require("@nestjs/common");
let OnboardingService = class OnboardingService {
    async getStatus(client, userId) {
        const { data, error } = await client
            .from('user_preferences')
            .select('onboarding_completed')
            .eq('user_id', userId)
            .maybeSingle();
        if (error || !data) {
            return { onboarding_completed: false };
        }
        return { onboarding_completed: data.onboarding_completed };
    }
    async markComplete(client, userId) {
        const { data: existing } = await client
            .from('user_preferences')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        if (existing) {
            const { error: updateError } = await client
                .from('user_preferences')
                .update({ onboarding_completed: true, updated_at: new Date().toISOString() })
                .eq('user_id', userId);
            if (updateError) {
                throw new Error(updateError.message);
            }
        }
        else {
            const { error: insertError } = await client
                .from('user_preferences')
                .insert({ user_id: userId, onboarding_completed: true });
            if (insertError) {
                throw new Error(insertError.message);
            }
        }
        return { success: true, onboarding_completed: true };
    }
};
exports.OnboardingService = OnboardingService;
exports.OnboardingService = OnboardingService = __decorate([
    (0, common_1.Injectable)()
], OnboardingService);
//# sourceMappingURL=onboarding.service.js.map