# ===== Build stage =====
FROM node:22 AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install --production

COPY . .

# ===== Production stage =====
FROM node:22-slim

WORKDIR /app

# Copy only necessary files from builder stage
COPY --from=builder /app /app

# Ensure uploads directory exists with proper permissions
RUN mkdir -p uploads && chown -R node:node /app

# Use non-root user for security
USER node

EXPOSE 3000

CMD ["node", "app.js"]
