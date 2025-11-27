import db from '../database';
import { User, UserStatus } from '../database/types';

export interface CreateUserInput {
  email: string;
  password_hash: string;
  first_name?: string;
  last_name?: string;
  phone_number?: string;
}

export interface UpdateUserInput {
  first_name?: string;
  last_name?: string;
  phone_number?: string;
  status?: UserStatus;
  email_verified?: boolean;
  email_verified_at?: Date;
  last_login_at?: Date;
}

class UserRepository {
  private tableName = 'users';

  async findById(id: string): Promise<User | undefined> {
    return db<User>(this.tableName).where({ id }).first();
  }

  async findByEmail(email: string): Promise<User | undefined> {
    return db<User>(this.tableName)
      .where({ email: email.toLowerCase() })
      .first();
  }

  async create(input: CreateUserInput): Promise<User> {
    const [user] = await db<User>(this.tableName)
      .insert({
        ...input,
        email: input.email.toLowerCase(),
        status: UserStatus.PENDING_VERIFICATION,
      })
      .returning('*');

    return user;
  }

  async update(id: string, input: UpdateUserInput): Promise<User | undefined> {
    const [user] = await db<User>(this.tableName)
      .where({ id })
      .update({
        ...input,
        updated_at: new Date(),
      })
      .returning('*');

    return user;
  }

  async delete(id: string): Promise<boolean> {
    const deletedCount = await db<User>(this.tableName).where({ id }).del();
    return deletedCount > 0;
  }

  async findAll(options: { limit?: number; offset?: number; status?: UserStatus } = {}): Promise<User[]> {
    const query = db<User>(this.tableName)
      .select('*')
      .orderBy('created_at', 'desc');

    if (options.status) {
      query.where({ status: options.status });
    }
    if (options.limit) {
      query.limit(options.limit);
    }
    if (options.offset) {
      query.offset(options.offset);
    }

    return query;
  }

  async updateLastLogin(id: string): Promise<void> {
    await db<User>(this.tableName)
      .where({ id })
      .update({ last_login_at: new Date() });
  }

  async updatePassword(id: string, newPasswordHash: string): Promise<void> {
    await db<User>(this.tableName)
      .where({ id })
      .update({
        password_hash: newPasswordHash,
        updated_at: new Date(),
      });
  }

  async emailExists(email: string): Promise<boolean> {
    const existing = await db<User>(this.tableName)
      .where({ email: email.toLowerCase() })
      .first('id');

    return !!existing;
  }

  async verifyEmail(id: string): Promise<User | undefined> {
    const [user] = await db<User>(this.tableName)
      .where({ id })
      .update({
        email_verified: true,
        email_verified_at: new Date(),
        status: UserStatus.ACTIVE,
        updated_at: new Date(),
      })
      .returning('*');

    return user;
  }

  async count(status?: UserStatus): Promise<number> {
    const query = db<User>(this.tableName).count<{ count: string }[]>('* as count');

    if (status) {
      query.where({ status });
    }

    const result = await query.first();
    return result ? parseInt(result.count, 10) : 0;
  }
}

export const userRepository = new UserRepository();
export default userRepository;


