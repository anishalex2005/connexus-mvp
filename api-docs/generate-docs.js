const express = require('express');
const swaggerUi = require('swagger-ui-express');
const yaml = require('js-yaml');
const fs = require('fs');
const path = require('path');

const apiSpec = yaml.load(
  fs.readFileSync(path.join(__dirname, 'openapi/connexus-api.yaml'), 'utf8')
);

const app = express();

app.use(
  '/api-docs',
  swaggerUi.serve,
  swaggerUi.setup(apiSpec, {
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: 'ConnexUS API Documentation',
  })
);

app.get('/', (req, res) => {
  res.redirect('/api-docs');
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`API Documentation available at http://localhost:${PORT}/api-docs`);
});


