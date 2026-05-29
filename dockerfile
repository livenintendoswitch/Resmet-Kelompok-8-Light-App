FROM node:20-alpine 
WORKDIR /app

COPY . .

RUN cd backend && npm install
RUN cd frontend && npm install
RUN cd frontend && npm install serve

EXPOSE 3000
EXPOSE 3001

CMD ["sh", "start.sh"]