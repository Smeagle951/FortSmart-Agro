# Dockerfile para API Backend do FortSmart Agro
# Backend intermediário entre o app Flutter e o Base44

FROM node:18-alpine

# Diretório de trabalho
WORKDIR /app

# Copiar arquivos de dependências
COPY server/package*.json ./

# Instalar dependências
RUN npm install --production

# Copiar código do servidor
COPY server/ .

# Porta que o Render vai usar
EXPOSE 10000

# Comando para iniciar o servidor
CMD ["node", "index.js"]

