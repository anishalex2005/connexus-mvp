// User status enum
export enum UserStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  SUSPENDED = 'suspended',
  PENDING_VERIFICATION = 'pending_verification',
}

// Call status enum
export enum CallStatus {
  INITIATED = 'initiated',
  RINGING = 'ringing',
  ANSWERED = 'answered',
  COMPLETED = 'completed',
  MISSED = 'missed',
  DECLINED = 'declined',
  FAILED = 'failed',
  TRANSFERRED = 'transferred',
}

// Call direction enum
export enum CallDirection {
  INBOUND = 'inbound',
  OUTBOUND = 'outbound',
}

// SMS status enum
export enum SmsStatus {
  PENDING = 'pending',
  SENT = 'sent',
  DELIVERED = 'delivered',
  FAILED = 'failed',
}

// User interface
export interface User {
  id: string;
  email: string;
  password_hash: string;
  first_name: string | null;
  last_name: string | null;
  phone_number: string | null;
  status: UserStatus;
  email_verified: boolean;
  email_verified_at: Date | null;
  last_login_at: Date | null;
  created_at: Date;
  updated_at: Date;
}

// Phone number interface
export interface PhoneNumber {
  id: string;
  user_id: string;
  phone_number: string;
  label: string | null;
  is_primary: boolean;
  is_verified: boolean;
  telnyx_connection_id: string | null;
  created_at: Date;
  updated_at: Date;
}

// Call record interface
export interface CallRecord {
  id: string;
  user_id: string;
  phone_number_id: string | null;
  caller_number: string;
  callee_number: string;
  direction: CallDirection;
  status: CallStatus;
  started_at: Date | null;
  answered_at: Date | null;
  ended_at: Date | null;
  duration_seconds: number | null;
  telnyx_call_control_id: string | null;
  ai_handled: boolean;
  transfer_to: string | null;
  notes: string | null;
  created_at: Date;
  updated_at: Date;
}

// AI configuration interface
export interface AiConfiguration {
  id: string;
  user_id: string;
  agent_name: string;
  personality: string | null;
  greeting_message: string | null;
  business_name: string | null;
  business_description: string | null;
  retell_agent_id: string | null;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

// Business hours interface
export interface BusinessHours {
  id: string;
  ai_configuration_id: string;
  day_of_week: number; // 0-6, Sunday-Saturday
  is_open: boolean;
  open_time: string | null; // HH:MM format
  close_time: string | null; // HH:MM format
  created_at: Date;
  updated_at: Date;
}

// SMS template interface
export interface SmsTemplate {
  id: string;
  user_id: string;
  name: string;
  content: string;
  category: string | null;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

// SMS message interface
export interface SmsMessage {
  id: string;
  user_id: string;
  call_record_id: string | null;
  template_id: string | null;
  from_number: string;
  to_number: string;
  content: string;
  status: SmsStatus;
  telnyx_message_id: string | null;
  sent_at: Date | null;
  delivered_at: Date | null;
  created_at: Date;
  updated_at: Date;
}

// FAQ/Knowledge base interface
export interface FaqEntry {
  id: string;
  user_id: string;
  ai_configuration_id: string;
  question: string;
  answer: string;
  category: string | null;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

// Blocked number interface
export interface BlockedNumber {
  id: string;
  user_id: string;
  phone_number: string;
  reason: string | null;
  created_at: Date;
}

// Refresh token interface
export interface RefreshToken {
  id: string;
  user_id: string;
  token_hash: string;
  expires_at: Date;
  created_at: Date;
  revoked_at: Date | null;
}


