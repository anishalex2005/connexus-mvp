import { io, type Socket } from 'socket.io-client';
import jwt from 'jsonwebtoken';

// Generate a test JWT access token (in production, obtain from auth endpoint)
const testToken = jwt.sign(
  {
    userId: 'test-user-123',
    email: 'test@example.com',
    type: 'access',
  },
  process.env.JWT_ACCESS_SECRET || 'your-super-secret-access-key-min-32-chars-long',
  { expiresIn: '1h' },
);

async function testWebSocket(): Promise<void> {
  // eslint-disable-next-line no-console
  console.log('Connecting to WebSocket server...');

  const socket: Socket = io('http://localhost:3000', {
    auth: {
      token: testToken,
    },
    transports: ['websocket'],
  });

  socket.on('connection:established', (data) => {
    // eslint-disable-next-line no-console
    console.log('Connection established:', data);

    socket.emit('ping', (timestamp: number) => {
      // eslint-disable-next-line no-console
      console.log('Pong received, server time:', new Date(timestamp));
    });

    socket.emit('presence:update', { status: 'online' });
    // eslint-disable-next-line no-console
    console.log('Presence update sent');

    socket.emit('room:join', 'test-room-1', (response: unknown) => {
      // eslint-disable-next-line no-console
      console.log('Room join response:', response);
    });
  });

  socket.on('presence:changed', (data) => {
    // eslint-disable-next-line no-console
    console.log('Presence changed:', data);
  });

  socket.on('connection:error', (error) => {
    // eslint-disable-next-line no-console
    console.error('Connection error:', error);
  });

  socket.on('disconnect', (reason) => {
    // eslint-disable-next-line no-console
    console.log('Disconnected:', reason);
  });

  socket.on('connect_error', (error) => {
    // eslint-disable-next-line no-console
    console.error('Failed to connect:', error.message);
  });

  await new Promise((resolve) => setTimeout(resolve, 5000));

  socket.disconnect();
  // eslint-disable-next-line no-console
  console.log('Test completed');
}

// eslint-disable-next-line @typescript-eslint/no-floating-promises
testWebSocket();


