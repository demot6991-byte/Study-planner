import { Injectable, BadRequestException } from '@nestjs/common';
import type { SupabaseClient } from '@supabase/supabase-js';

const ALLOWED_TABLES = new Set([
  'books',
  'study_sessions',
  'journal_entries',
  'schedule_entries',
  'settings',
  'weekly_goals',
  'instrument_practices',
  'weekly_reviews',
  'tasks',
  'fixed_activities',
  'study_subjects',
  'daily_progress',
  'user_preferences',
]);

@Injectable()
export class CrudService {
  private validateTable(table: string) {
    if (!ALLOWED_TABLES.has(table)) {
      throw new BadRequestException(`Table '${table}' is not allowed`);
    }
  }

  async getAll(table: string, query: any, client: SupabaseClient) {
    this.validateTable(table);

    let q = client.from(table).select(typeof query.select === 'string' ? query.select : '*');

    if (query.filter_field && query.filter_value) {
      q = q.eq(String(query.filter_field), String(query.filter_value));
    }

    if (query.filter_in && query.filter_field) {
      const values = String(query.filter_in).split(',');
      q = q.in(String(query.filter_field), values);
    }

    if (query.order) {
      const [column, ascending] = String(query.order).split(':');
      q = q.order(column, { ascending: ascending !== 'false' });
    }

    if (query.limit) {
      q = q.limit(parseInt(String(query.limit), 10));
    }

    if (query.single === 'true') {
      const { data, error } = await q.single();
      if (error && error.code !== 'PGRST116') {
        throw new BadRequestException(error.message);
      }
      return { data };
    }

    if (query.maybe_single === 'true') {
      const { data, error } = await q.maybeSingle();
      if (error) {
        throw new BadRequestException(error.message);
      }
      return { data };
    }

    const { data, error } = await q;
    if (error) {
      throw new BadRequestException(error.message);
    }
    return { data };
  }

  async insert(table: string, body: any, client: SupabaseClient) {
    this.validateTable(table);
    const rows = Array.isArray(body) ? body : [body];

    const { data, error } = await client.from(table).insert(rows).select();
    if (error) {
      throw new BadRequestException(error.message);
    }
    return { data };
  }

  async update(table: string, query: any, body: any, client: SupabaseClient) {
    this.validateTable(table);

    if (!query.filter_field || !query.filter_value) {
      throw new BadRequestException('filter_field and filter_value required for PUT');
    }

    const { data, error } = await client
      .from(table)
      .update(body)
      .eq(String(query.filter_field), String(query.filter_value))
      .select();
    if (error) {
      throw new BadRequestException(error.message);
    }
    return { data };
  }

  async remove(table: string, query: any, client: SupabaseClient) {
    this.validateTable(table);

    if (!query.filter_field) {
      throw new BadRequestException('filter_field required for DELETE');
    }

    let q = client.from(table).delete();

    if (query.filter_in) {
      const values = String(query.filter_in).split(',');
      q = q.in(String(query.filter_field), values);
    } else if (query.filter_value) {
      q = q.eq(String(query.filter_field), String(query.filter_value));
    } else {
      throw new BadRequestException('filter_value or filter_in required for DELETE');
    }

    const { error } = await q;
    if (error) {
      throw new BadRequestException(error.message);
    }
    return { success: true };
  }
}
