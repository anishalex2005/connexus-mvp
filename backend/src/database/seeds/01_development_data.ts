import { Knex } from 'knex';
import crypto from 'crypto';

// Simple password hash for development (DO NOT use in production)
// Proper hashing with bcrypt will be implemented in the auth task.
function hashPassword(password: string): string {
  return crypto.createHash('sha256').update(password).digest('hex');
}

export async function seed(knex: Knex): Promise<void> {
  // Only run seeds in non-production environments
  if (process.env.NODE_ENV === 'production') {
    // eslint-disable-next-line no-console
    console.log('Skipping seeds in production');
    return;
  }

  // Clear existing data (in reverse order of dependencies)
  await knex('refresh_tokens').del();
  await knex('blocked_numbers').del();
  await knex('faq_entries').del();
  await knex('sms_messages').del();
  await knex('sms_templates').del();
  await knex('call_records').del();
  await knex('business_hours').del();
  await knex('ai_configurations').del();
  await knex('phone_numbers').del();
  await knex('users').del();

  // Insert test user
  const [testUser] = await knex('users')
    .insert({
      email: 'test@connexus.dev',
      password_hash: hashPassword('TestPassword123!'),
      first_name: 'Test',
      last_name: 'User',
      phone_number: '+15551234567',
      status: 'active',
      email_verified: true,
      email_verified_at: new Date(),
    })
    .returning('*');

  // eslint-disable-next-line no-console
  console.log('Created test user:', testUser.email);

  // Insert phone numbers for test user
  await knex('phone_numbers').insert([
    {
      user_id: testUser.id,
      phone_number: '+15551234567',
      label: 'Primary',
      is_primary: true,
      is_verified: true,
    },
    {
      user_id: testUser.id,
      phone_number: '+15559876543',
      label: 'Work',
      is_primary: false,
      is_verified: false,
    },
  ]);

  // Insert AI configuration
  const [aiConfig] = await knex('ai_configurations')
    .insert({
      user_id: testUser.id,
      agent_name: 'ConnexUS Assistant',
      personality: 'professional',
      greeting_message: 'Hello! Thank you for calling. How may I assist you today?',
      business_name: 'ConnexUS Demo',
      business_description: 'AI-powered communication platform',
      is_active: true,
    })
    .returning('*');

  // Insert business hours (Mon-Fri 9am-5pm)
  const businessHours = [];
  for (let day = 0; day <= 6; day += 1) {
    businessHours.push({
      ai_configuration_id: aiConfig.id,
      day_of_week: day,
      is_open: day >= 1 && day <= 5, // Monday to Friday
      open_time: day >= 1 && day <= 5 ? '09:00:00' : null,
      close_time: day >= 1 && day <= 5 ? '17:00:00' : null,
    });
  }
  await knex('business_hours').insert(businessHours);

  // Insert SMS templates
  await knex('sms_templates').insert([
    {
      user_id: testUser.id,
      name: 'Call Back',
      content: "Sorry I missed your call. I'll get back to you as soon as possible.",
      category: 'general',
      is_active: true,
    },
    {
      user_id: testUser.id,
      name: 'In Meeting',
      content: "I'm currently in a meeting. Can I call you back in about an hour?",
      category: 'busy',
      is_active: true,
    },
    {
      user_id: testUser.id,
      name: 'Thank You',
      content: 'Thank you for your call today. Please let me know if you have any questions.',
      category: 'followup',
      is_active: true,
    },
  ]);

  // Insert FAQ entries
  await knex('faq_entries').insert([
    {
      user_id: testUser.id,
      ai_configuration_id: aiConfig.id,
      question: 'What are your business hours?',
      answer: 'Our business hours are Monday through Friday, 9 AM to 5 PM.',
      category: 'general',
      is_active: true,
    },
    {
      user_id: testUser.id,
      ai_configuration_id: aiConfig.id,
      question: 'How can I schedule an appointment?',
      answer:
        'You can schedule an appointment by calling during business hours or leaving a message with your preferred time.',
      category: 'appointments',
      is_active: true,
    },
  ]);

  // Insert sample call records
  const now = new Date();
  await knex('call_records').insert([
    {
      user_id: testUser.id,
      caller_number: '+15559998888',
      callee_number: '+15551234567',
      direction: 'inbound',
      status: 'completed',
      started_at: new Date(now.getTime() - 3600000), // 1 hour ago
      answered_at: new Date(now.getTime() - 3600000 + 5000), // 5 seconds after start
      ended_at: new Date(now.getTime() - 3600000 + 185000), // ~3 minutes call
      duration_seconds: 180,
      ai_handled: true,
      notes: 'Customer inquiry about services',
    },
    {
      user_id: testUser.id,
      caller_number: '+15557776666',
      callee_number: '+15551234567',
      direction: 'inbound',
      status: 'missed',
      started_at: new Date(now.getTime() - 7200000), // 2 hours ago
      ai_handled: false,
    },
  ]);

  // Insert blocked number
  await knex('blocked_numbers').insert({
    user_id: testUser.id,
    phone_number: '+15550000000',
    reason: 'Spam caller',
  });

  // eslint-disable-next-line no-console
  console.log('✅ Development seed data inserted successfully');
}


