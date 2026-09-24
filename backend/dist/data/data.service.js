"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DataService = void 0;
const common_1 = require("@nestjs/common");
let DataService = class DataService {
    async loadAll(client) {
        const [settingsRes, fixedRes, scheduleRes, subjectsRes, tasksRes, sessionsRes, journalRes, goalsRes, progressRes,] = await Promise.all([
            client.from('settings').select('*').limit(1).maybeSingle(),
            client.from('fixed_activities').select('*').order('sort_order'),
            client.from('schedule_entries').select('*').order('weekday, sort_order'),
            client.from('study_subjects').select('*').order('sort_order'),
            client.from('tasks').select('*').order('due_date'),
            client.from('study_sessions').select('*').order('date, start_time'),
            client.from('journal_entries').select('*').order('entry_date', { ascending: false }).limit(30),
            client.from('weekly_goals').select('*'),
            client.from('daily_progress').select('*').order('progress_date', { ascending: false }).limit(60),
        ]);
        return {
            settings: settingsRes.data || null,
            fixedActivities: fixedRes.data || [],
            scheduleEntries: scheduleRes.data || [],
            subjects: subjectsRes.data || [],
            tasks: tasksRes.data || [],
            sessions: sessionsRes.data || [],
            journalEntries: journalRes.data || [],
            weeklyGoals: goalsRes.data || [],
            dailyProgress: progressRes.data || [],
        };
    }
};
exports.DataService = DataService;
exports.DataService = DataService = __decorate([
    (0, common_1.Injectable)()
], DataService);
//# sourceMappingURL=data.service.js.map