FROM node:24-alpine AS build
WORKDIR /app
COPY orbit-feast-source.tar.gz /tmp/orbit-feast-source.tar.gz
RUN tar -xzf /tmp/orbit-feast-source.tar.gz -C /app
RUN --mount=type=secret,id=proxy_ca \
    if [ -f /run/secrets/proxy_ca ]; then export NODE_EXTRA_CA_CERTS=/run/secrets/proxy_ca; fi; npm ci
RUN npm run build

FROM node:24-alpine AS production
WORKDIR /app
ENV NODE_ENV=production HOST=0.0.0.0 PORT=3001
COPY --from=build --chown=node:node /app/package*.json ./
COPY --from=build --chown=node:node /app/apps/client/package.json apps/client/package.json
COPY --from=build --chown=node:node /app/apps/server/package.json apps/server/package.json
RUN --mount=type=secret,id=proxy_ca \
    if [ -f /run/secrets/proxy_ca ]; then export NODE_EXTRA_CA_CERTS=/run/secrets/proxy_ca; fi; npm ci --omit=dev && npm cache clean --force
COPY --from=build --chown=node:node /app/dist ./dist
USER node
EXPOSE 3001
CMD ["node","dist/server.js"]
