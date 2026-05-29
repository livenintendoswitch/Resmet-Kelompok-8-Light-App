#!/bin/sh

echo "waiting for db to initialize..."

sleep 25

echo "Booting Backend on Port 3001..."
cd backend
npm start &

echo "Building static React frontend..."
cd ../frontend
npm run build

echo "Serving Frontend on Port 3000..."
npx serve -s dist -l 3000