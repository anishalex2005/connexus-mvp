import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  // Enable UUID extension
  await knex.raw('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');

  // Create users table
  await knex.schema.createTable('users', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.string('email', 255).notNullable().unique();
    table.string('password_hash', 255).notNullable();
    table.string('first_name', 100);
    table.string('last_name', 100);
    table.string('phone_number', 20);
    table
      .enum('status', ['active', 'inactive', 'suspended', 'pending_verification'])
      .notNullable()
      .defaultTo('pending_verification');
    table.boolean('email_verified').notNullable().defaultTo(false);
    table.timestamp('email_verified_at');
    table.timestamp('last_login_at');
    table.timestamps(true, true);

    // Indexes
    table.index('email');
    table.index('status');
    table.index('created_at');
  });

  // Create phone_numbers table
  await knex.schema.createTable('phone_numbers', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('phone_number', 20).notNullable();
    table.string('label', 50);
    table.boolean('is_primary').notNullable().defaultTo(false);
    table.boolean('is_verified').notNullable().defaultTo(false);
    table.string('telnyx_connection_id', 100);
    table.timestamps(true, true);

    // Indexes
    table.index('user_id');
    table.index('phone_number');
    table.unique(['user_id', 'phone_number']);
  });

  // Create ai_configurations table
  await knex.schema.createTable('ai_configurations', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('agent_name', 100).notNullable();
    table.text('personality');
    table.text('greeting_message');
    table.string('business_name', 200);
    table.text('business_description');
    table.string('retell_agent_id', 100);
    table.boolean('is_active').notNullable().defaultTo(true);
    table.timestamps(true, true);

    // Indexes
    table.index('user_id');
    table.index('retell_agent_id');
  });

  // Create business_hours table
  await knex.schema.createTable('business_hours', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table
      .uuid('ai_configuration_id')
      .notNullable()
      .references('id')
      .inTable('ai_configurations')
      .onDelete('CASCADE');
    table.integer('day_of_week').notNullable(); // 0-6, Sunday-Saturday
    table.boolean('is_open').notNullable().defaultTo(true);
    table.time('open_time');
    table.time('close_time');
    table.timestamps(true, true);

    // Indexes
    table.index('ai_configuration_id');
    table.unique(['ai_configuration_id', 'day_of_week']);
  });

  // Create call_records table
  await knex.schema.createTable('call_records', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.uuid('phone_number_id').references('id').inTable('phone_numbers').onDelete('SET NULL');
    table.string('caller_number', 20).notNullable();
    table.string('callee_number', 20).notNullable();
    table.enum('direction', ['inbound', 'outbound']).notNullable();
    table
      .enum('status', [
        'initiated',
        'ringing',
        'answered',
        'completed',
        'missed',
        'declined',
        'failed',
        'transferred',
      ])
      .notNullable()
      .defaultTo('initiated');
    table.timestamp('started_at');
    table.timestamp('answered_at');
    table.timestamp('ended_at');
    table.integer('duration_seconds');
    table.string('telnyx_call_control_id', 100);
    table.boolean('ai_handled').notNullable().defaultTo(false);
    table.string('transfer_to', 20);
    table.text('notes');
    table.timestamps(true, true);

    // Indexes
    table.index('user_id');
    table.index('phone_number_id');
    table.index('status');
    table.index('direction');
    table.index('started_at');
    table.index('created_at');
    table.index('telnyx_call_control_id');
  });

  // Create sms_templates table
  await knex.schema.createTable('sms_templates', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('name', 100).notNullable();
    table.text('content').notNullable();
    table.string('category', 50);
    table.boolean('is_active').notNullable().defaultTo(true);
    table.timestamps(true, true);

    // Indexes
    table.index('user_id');
    table.index('category');
    table.unique(['user_id', 'name']);
  });

  // Create sms_messages table
  await knex.schema.createTable('sms_messages', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.uuid('call_record_id').references('id').inTable('call_records').onDelete('SET NULL');
    table.uuid('template_id').references('id').inTable('sms_templates').onDelete('SET NULL');
    table.string('from_number', 20).notNullable();
    table.string('to_number', 20).notNullable();
    table.text('content').notNullable();
    table.enum('status', ['pending', 'sent', 'delivered', 'failed']).notNullable().defaultTo('pending');
    table.string('telnyx_message_id', 100);
    table.timestamp('sent_at');
    table.timestamp('delivered_at');
    table.timestamps(true, true);

    // Indexes
    table.index('user_id');
    table.index('call_record_id');
    table.index('status');
    table.index('created_at');
    table.index('telnyx_message_id');
  });

  // Create faq_entries table
  await knex.schema.createTable('faq_entries', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table
      .uuid('ai_configuration_id')
      .notNullable()
      .references('id')
      .inTable('ai_configurations')
      .onDelete('CASCADE');
    table.text('question').notNullable();
    table.text('answer').notNullable();
    table.string('category', 50);
    table.boolean('is_active').notNullable().defaultTo(true);
    table.timestamps(true, true);

    // Indexes
    table.index('user_id');
    table.index('ai_configuration_id');
    table.index('category');
  });

  // Create blocked_numbers table
  await knex.schema.createTable('blocked_numbers', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('phone_number', 20).notNullable();
    table.string('reason', 255);
    table.timestamp('created_at').notNullable().defaultTo(knex.fn.now());

    // Indexes
    table.index('user_id');
    table.index('phone_number');
    table.unique(['user_id', 'phone_number']);
  });

  // Create refresh_tokens table
  await knex.schema.createTable('refresh_tokens', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('token_hash', 255).notNullable();
    table.timestamp('expires_at').notNullable();
    table.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    table.timestamp('revoked_at');

    // Indexes
    table.index('user_id');
    table.index('token_hash');
    table.index('expires_at');
  });
}

export async function down(knex: Knex): Promise<void> {
  // Drop tables in reverse order of creation (respect foreign keys)
  await knex.schema.dropTableIfExists('refresh_tokens');
  await knex.schema.dropTableIfExists('blocked_numbers');
  await knex.schema.dropTableIfExists('faq_entries');
  await knex.schema.dropTableIfExists('sms_messages');
  await knex.schema.dropTableIfExists('sms_templates');
  await knex.schema.dropTableIfExists('call_records');
  await knex.schema.dropTableIfExists('business_hours');
  await knex.schema.dropTableIfExists('ai_configurations');
  await knex.schema.dropTableIfExists('phone_numbers');
  await knex.schema.dropTableIfExists('users');
}


