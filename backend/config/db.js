const mongoose = require('mongoose');
const path = require('path');

const connectDB = async () => {
  try {
    const connStr = process.env.MONGO_URI || 'mongodb://localhost:27017/unirise';
    console.log(`Connecting to MongoDB... Target: ${connStr.split('@')[1] || connStr}`);
    
    // Set connection options
    const conn = await mongoose.connect(connStr, {
      serverSelectionTimeoutMS: 3000
    });

    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.warn(`MongoDB Atlas connection warning/error: ${error.message}`);
    console.log('Attempting memory fallback for prototype execution...');
    try {
      process.env.MONGOMS_DOWNLOAD_DIR = path.join(__dirname, '../.mongo-bin');
      const { MongoMemoryServer } = require('mongodb-memory-server');
      const mongoServer = await MongoMemoryServer.create({
        instance: { dbName: 'unirise' },
        binary: { version: '6.0.5' }
      });
      const mongoUri = mongoServer.getUri();
      await mongoose.connect(mongoUri);
      console.log(`Fallback Mongo Memory Server connected successfully at ${mongoUri}`);
    } catch (fallbackError) {
      console.warn('Memory server fallback notice:', fallbackError.message);
      try {
        await mongoose.connect('mongodb://127.0.0.1:27017/unirise', { serverSelectionTimeoutMS: 2000 });
        console.log('Connected to local MongoDB instance.');
      } catch (localErr) {
        console.warn('Database running in prototype execution mode.');
      }
    }
  }
};

module.exports = connectDB;
