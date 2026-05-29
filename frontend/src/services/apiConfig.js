import axios from 'axios';

// Check if Vite built this for production
const isProd = import.meta.env.PROD;

// If in production, dynamically grab the AWS IP from the browser and force port 3001
const baseURL = isProd ? `http://${window.location.hostname}:3001` : '';

// Create a custom Axios instance that automatically uses the right URL
export const api = axios.create({
  baseURL: baseURL
});