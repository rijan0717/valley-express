const mongoose = require('mongoose');

// 127.0.0.1 rather than localhost: mongod.cfg binds only the IPv4 loopback,
// while Windows resolves "localhost" to ::1 first, so the default URI can be
// refused even with the server up.
const DEFAULT_URI = 'mongodb://127.0.0.1:27017/valley_express';

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI || DEFAULT_URI, {
      // Without this, a request made while the server is unreachable hangs on
      // Mongoose's buffer until the client gives up, so the API stops
      // responding instead of failing. 5s turns that into a prompt error.
      serverSelectionTimeoutMS: 5000,
    });
    console.log(`[Database] MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`[Database Error] ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
