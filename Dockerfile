FROM node:22-alpine
WORKDIR /usr/app
COPY index.js index.js
COPY node_modules node_modules
CMD ["node", "index.js"]
