import axios from 'axios';
const baseURL = window._env_?.VITE_API_URL || import.meta.env.VITE_API_URL || '';

export const api = axios.create({
  baseURL: baseURL
});