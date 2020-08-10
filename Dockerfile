# Stage 1 - the build react app
FROM node:lts-alpine as build-deps
RUN apk add --no-cache python2 build-base
WORKDIR /usr/src/app
COPY client/package.json client/package-lock.json ./
RUN npm i

COPY client/ ./
RUN npm run build

# Stage 2 - the production environment
FROM node:lts-alpine

RUN apk add --no-cache tini python2 build-base
ENV NODE_ENV production
WORKDIR /usr/src/app
RUN chown -R node:node /usr/src/app/
EXPOSE 4654

COPY server/package.json server/package-lock.json ./
RUN npm i --production

COPY --from=build-deps /usr/src/app/build /usr/src/app/public
COPY /server ./

# USER 1000 is the "node" user
# This is to avoid the "container has runAsNonRoot and image has non-numeric user (node), cannot verify user is non-root"
# in clusters with PSP enabled
USER 1000

ENTRYPOINT ["/sbin/tini", "--", "node", "."]
