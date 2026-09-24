import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  private readonly url: string;
  private readonly anonKey: string;
  readonly client: SupabaseClient;

  constructor() {
    this.url = process.env.SUPABASE_URL as string;
    this.anonKey = process.env.SUPABASE_ANON_KEY as string;

    if (!this.url || !this.anonKey) {
      throw new Error('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
    }

    this.client = createClient(this.url, this.anonKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });
  }

  createUserClient(accessToken: string): SupabaseClient {
    return createClient(this.url, this.anonKey, {
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

  async refreshSession(refreshToken: string) {
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
}
