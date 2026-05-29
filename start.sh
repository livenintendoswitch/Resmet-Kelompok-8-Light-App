#!/bin/sh

echo "Waiting 10 seconds for Database to initialize..."
sleep 15

echo "Running Database Migrations..."
cd backend
npx sequelize-cli db:migrate
npx sequelize-cli db:seed:all

echo "Booting Backend on Port 3001..."
npm start &

echo "Building static React frontend..."
cd ../frontend
npm run build

echo "Serving Frontend on Port 3000..."
npx serve -s dist -l 3000