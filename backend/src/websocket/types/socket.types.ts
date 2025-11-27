import type { Socket } from 'socket.io';

// User session data attached to socket
export interface SocketUserData {
  userId: string;
  email: string;
  phoneNumbers: string[];
  connectedAt: Date;
  lastActivity: Date;
}

// Room types for organizing connections
export enum RoomType {
  USER = 'user', // Individual user room
  CALL = 'call', // Active call room
  PHONE = 'phone', // Phone number specific room
  BROADCAST = 'broadcast', // System-wide broadcasts
}

// Client-to-server events
export interface ClientToServerEvents {
  // Connection events
  'auth:authenticate': (token: string, callback: (response: AuthResponse) => void) => void;
  'auth:refresh': (token: string, callback: (response: AuthResponse) => void) => void;

  // Presence events
  'presence:update': (status: PresenceStatus) => void;
  'presence:typing': (data: TypingData) => void;

  // Call events (will be used by Telnyx integration)
  'call:initiate': (data: CallInitiateData, callback: (response: CallResponse) => void) => void;
  'call:answer': (callId: string, callback: (response: CallResponse) => void) => void;
  'call:reject': (callId: string, reason?: string) => void;
  'call:hangup': (callId: string) => void;
  'call:mute': (callId: string, muted: boolean) => void;
  'call:hold': (callId: string, held: boolean) => void;

  // Room events
  'room:join': (roomId: string, callback: (response: RoomResponse) => void) => void;
  'room:leave': (roomId: string) => void;

  // Ping for connection health
  ping: (callback: (timestamp: number) => void) => void;
}

// Server-to-client events
export interface ServerToClientEvents {
  // Connection events
  'connection:established': (data: ConnectionEstablishedData) => void;
  'connection:error': (error: SocketError) => void;

  // Presence events
  'presence:changed': (data: PresenceChangedData) => void;
  'presence:typing': (data: TypingData) => void;

  // Call events
  'call:incoming': (data: IncomingCallData) => void;
  'call:state_changed': (data: CallStateData) => void;
  'call:ended': (data: CallEndedData) => void;
  'call:quality': (data: CallQualityData) => void;

  // Notification events
  'notification:new': (data: NotificationData) => void;

  // System events
  'system:maintenance': (data: MaintenanceData) => void;
  'system:error': (error: SocketError) => void;

  // Pong response
  pong: (timestamp: number) => void;
}

// Inter-server events (for scaling with Redis)
export interface InterServerEvents {
  'user:force_disconnect': (userId: string) => void;
  'broadcast:message': (data: BroadcastData) => void;
}

// Socket.IO server data
export interface SocketData {
  user: SocketUserData;
  rooms: Set<string>;
  connectionId: string;
}

// Extended Socket with user data
export interface AuthenticatedSocket
  extends Socket<ClientToServerEvents, ServerToClientEvents, InterServerEvents, SocketData> {
  user: SocketUserData;
}

// Supporting types
export interface AuthResponse {
  success: boolean;
  message?: string;
  user?: SocketUserData;
}

export interface PresenceStatus {
  status: 'online' | 'away' | 'busy' | 'offline';
  customMessage?: string;
}

export interface TypingData {
  roomId: string;
  userId: string;
  isTyping: boolean;
}

export interface CallInitiateData {
  toNumber: string;
  fromNumber: string;
  metadata?: Record<string, unknown>;
}

export interface CallResponse {
  success: boolean;
  callId?: string;
  error?: string;
}

export interface RoomResponse {
  success: boolean;
  roomId?: string;
  participants?: string[];
  error?: string;
}

export interface ConnectionEstablishedData {
  connectionId: string;
  serverTime: Date;
  user: SocketUserData;
}

export interface PresenceChangedData {
  userId: string;
  status: PresenceStatus;
  timestamp: Date;
}

export interface IncomingCallData {
  callId: string;
  fromNumber: string;
  toNumber: string;
  callerName?: string;
  timestamp: Date;
}

export interface CallStateData {
  callId: string;
  state: 'ringing' | 'connecting' | 'active' | 'held' | 'transferring';
  duration?: number;
  metadata?: Record<string, unknown>;
}

export interface CallEndedData {
  callId: string;
  reason: 'completed' | 'rejected' | 'missed' | 'failed' | 'transferred';
  duration: number;
  timestamp: Date;
}

export interface CallQualityData {
  callId: string;
  quality: 'excellent' | 'good' | 'fair' | 'poor';
  metrics: {
    latency: number;
    jitter: number;
    packetLoss: number;
  };
}

export interface NotificationData {
  id: string;
  type: 'call' | 'message' | 'system' | 'ai';
  title: string;
  body: string;
  data?: Record<string, unknown>;
  timestamp: Date;
}

export interface MaintenanceData {
  type: 'scheduled' | 'emergency';
  message: string;
  startTime?: Date;
  estimatedDuration?: number;
}

export interface SocketError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

export interface BroadcastData {
  type: string;
  payload: unknown;
  excludeUsers?: string[];
}


