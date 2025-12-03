import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  // Create user_telephony_credentials table.
  await knex.schema.createTable('user_telephony_credentials', (table) => {
    table
      .uuid('id')
      .primary()
      .defaultTo(knex.raw('uuid_generate_v4()'));

    table
      .uuid('user_id')
      .notNullable()
      .unique()
      .references('id')
      .inTable('users')
      .onDelete('CASCADE');

    // SIP Credentials.
    table.string('sip_username', 255).notNullable();
    table.string('sip_password', 255).notNullable();

    // Caller ID configuration.
    table.string('caller_id_name', 100);
    table.string('caller_id_number', 20);

    // Push notification token.
    table.text('fcm_token');

    // Status tracking.
    table.boolean('is_active').defaultTo(true);
    table.timestamp('last_connected_at');
    table.integer('connection_count').defaultTo(0);

    // Timestamps.
    table.timestamps(true, true);
  });

  // Index for faster lookups.
  await knex.schema.raw(`
    CREATE INDEX idx_telephony_credentials_user_active
    ON user_telephony_credentials(user_id, is_active)
  `);

  // Create telephony_connection_logs table for debugging.
  await knex.schema.createTable('telephony_connection_logs', (table) => {
    table
      .uuid('id')
      .primary()
      .defaultTo(knex.raw('uuid_generate_v4()'));

    table
      .uuid('user_id')
      .notNullable()
      .references('id')
      .inTable('users')
      .onDelete('CASCADE');

    table
      .enu('event_type', ['connect', 'disconnect', 'error', 'retry'], {
        useNative: false,
        enumName: 'telephony_event_type',
      })
      .notNullable();

    table.string('status', 50);
    table.text('message');
    table.jsonb('metadata');
    table.timestamp('created_at').defaultTo(knex.fn.now());
  });

  await knex.schema.raw(`
    CREATE INDEX idx_connection_logs_user_created
    ON telephony_connection_logs(user_id, created_at DESC)
  `);
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('telephony_connection_logs');
  await knex.schema.dropTableIfExists('user_telephony_credentials');
  await knex.schema.raw('DROP TYPE IF EXISTS telephony_event_type');
}


