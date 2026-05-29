FROM node:18-alpine
WORKDIR /app

COPY . .

RUN cd backend && npm ci --only=production

RUN cd frontend && npm ci --only=production
RUN cd frontend && npm install serve

EXPOSE 3000
EXPOSE 3001

CMD ["sh", "start.sh"]