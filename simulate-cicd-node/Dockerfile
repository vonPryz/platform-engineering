FROM node:20-slim

# --- v1 ---
FROM node:20-slim AS v1
WORKDIR /app
COPY package/package.v1.json ./package.json
COPY package/package-lock.v1.json ./package-lock.json
COPY tsconfig.json ./tsconfig.json
RUN npm ci
COPY app ./app
COPY tests ./tests
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["npm", "test", "--silent"]

# --- v2 (intentionally broken lockfile) ---
FROM node:20-slim AS v2
WORKDIR /app
COPY package/package.v2.json ./package.json
COPY package/package-lock.v1.json ./package-lock.json
COPY tsconfig.json ./tsconfig.json
RUN npm ci
COPY app ./app
COPY tests ./tests
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["npm", "test", "--silent"]

# --- v3 (lockfile fixed) ---
FROM node:20-slim AS v3
WORKDIR /app
COPY package/package.v3.json ./package.json
COPY package/package-lock.v3.json ./package-lock.json
COPY tsconfig.json ./tsconfig.json
RUN npm ci
COPY app ./app
COPY tests ./tests
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["npm", "test", "--silent"]
