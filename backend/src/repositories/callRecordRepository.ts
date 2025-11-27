import db from '../database';
import { CallRecord, CallDirection, CallStatus } from '../database/types';

export interface CreateCallRecordInput {
  user_id: string;
  phone_number_id?: string;
  caller_number: string;
  callee_number: string;
  direction: CallDirection;
  telnyx_call_control_id?: string;
}

export interface UpdateCallRecordInput {
  status?: CallStatus;
  answered_at?: Date;
  ended_at?: Date;
  duration_seconds?: number;
  ai_handled?: boolean;
  transfer_to?: string;
  notes?: string;
}

export interface CallRecordFilters {
  user_id: string;
  direction?: CallDirection;
  status?: CallStatus;
  ai_handled?: boolean;
  from_date?: Date;
  to_date?: Date;
  limit?: number;
  offset?: number;
}

class CallRecordRepository {
  private tableName = 'call_records';

  async findById(id: string): Promise<CallRecord | undefined> {
    return db<CallRecord>(this.tableName).where({ id }).first();
  }

  async findByTelnyxId(telnyxCallControlId: string): Promise<CallRecord | undefined> {
    return db<CallRecord>(this.tableName)
      .where({ telnyx_call_control_id: telnyxCallControlId })
      .first();
  }

  async create(input: CreateCallRecordInput): Promise<CallRecord> {
    const [record] = await db<CallRecord>(this.tableName)
      .insert({
        ...input,
        status: CallStatus.INITIATED,
        started_at: new Date(),
      })
      .returning('*');

    return record;
  }

  async update(id: string, input: UpdateCallRecordInput): Promise<CallRecord | undefined> {
    const [record] = await db<CallRecord>(this.tableName)
      .where({ id })
      .update({
        ...input,
        updated_at: new Date(),
      })
      .returning('*');

    return record;
  }

  async findByUser(filters: CallRecordFilters): Promise<CallRecord[]> {
    const query = db<CallRecord>(this.tableName)
      .where({ user_id: filters.user_id })
      .orderBy('created_at', 'desc');

    if (filters.direction) {
      query.where({ direction: filters.direction });
    }
    if (filters.status) {
      query.where({ status: filters.status });
    }
    if (filters.ai_handled !== undefined) {
      query.where({ ai_handled: filters.ai_handled });
    }
    if (filters.from_date) {
      query.where('started_at', '>=', filters.from_date);
    }
    if (filters.to_date) {
      query.where('started_at', '<=', filters.to_date);
    }
    if (filters.limit) {
      query.limit(filters.limit);
    }
    if (filters.offset) {
      query.offset(filters.offset);
    }

    return query;
  }

  async getStats(
    userId: string,
    days: number = 30
  ): Promise<{
    total: number;
    inbound: number;
    outbound: number;
    answered: number;
    missed: number;
    ai_handled: number;
    total_duration: number;
  }> {
    const fromDate = new Date();
    fromDate.setDate(fromDate.getDate() - days);

    const stats = await db(this.tableName)
      .where({ user_id: userId })
      .where('created_at', '>=', fromDate)
      .select(
        db.raw('COUNT(*) as total'),
        db.raw("COUNT(*) FILTER (WHERE direction = 'inbound') as inbound"),
        db.raw("COUNT(*) FILTER (WHERE direction = 'outbound') as outbound"),
        db.raw("COUNT(*) FILTER (WHERE status = 'answered' OR status = 'completed') as answered"),
        db.raw("COUNT(*) FILTER (WHERE status = 'missed') as missed"),
        db.raw('COUNT(*) FILTER (WHERE ai_handled = true) as ai_handled'),
        db.raw('COALESCE(SUM(duration_seconds), 0) as total_duration')
      )
      .first();

    const toInt = (value: unknown): number => {
      if (typeof value === 'number') return value;
      if (typeof value === 'string') return parseInt(value, 10) || 0;
      return 0;
    };

    return {
      total: toInt(stats?.total),
      inbound: toInt(stats?.inbound),
      outbound: toInt(stats?.outbound),
      answered: toInt(stats?.answered),
      missed: toInt(stats?.missed),
      ai_handled: toInt(stats?.ai_handled),
      total_duration: toInt(stats?.total_duration),
    };
  }
}

export const callRecordRepository = new CallRecordRepository();
export default callRecordRepository;


