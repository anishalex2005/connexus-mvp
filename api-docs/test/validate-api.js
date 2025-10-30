#!/usr/bin/env node

const path = require('path');
const SwaggerParser = require('@apidevtools/swagger-parser');

async function validateAPI() {
  console.log('🔍 Validating ConnexUS API specification...\n');
  try {
    const apiPath = path.join(__dirname, '../openapi/connexus-api.yaml');
    const api = await SwaggerParser.validate(apiPath);
    console.log('✅ API specification is valid!');
    console.log(`   Name: ${api.info.title}`);
    console.log(`   Version: ${api.info.version}`);
    console.log(`   Base URL: ${api.servers?.[0]?.url}`);

    const paths = Object.keys(api.paths || {});
    let endpointCount = 0;
    const methodCounts = {};
    paths.forEach((p) => {
      const methods = Object.keys(api.paths[p]).filter((m) => ['get', 'post', 'put', 'delete', 'patch'].includes(m));
      methods.forEach((m) => {
        endpointCount += 1;
        methodCounts[m] = (methodCounts[m] || 0) + 1;
      });
    });

    console.log('\n📊 API Statistics:');
    console.log(`   Total Endpoints: ${endpointCount}`);
    console.log(`   Paths: ${paths.length}`);
    console.log('   Methods:');
    Object.entries(methodCounts).forEach(([m, c]) => console.log(`     ${m.toUpperCase()}: ${c}`));

    console.log('\n📁 API Tags:');
    (api.tags || []).forEach((t) => console.log(`   - ${t.name}: ${t.description}`));

    console.log('\n🔒 Security Schemes:');
    const schemes = api.components?.securitySchemes || {};
    Object.entries(schemes).forEach(([name, scheme]) => {
      console.log(`   - ${name}: ${scheme.type} ${scheme.scheme ? `(${scheme.scheme})` : ''}`);
    });

    console.log('\n📝 Endpoint List:');
    paths.forEach((p) => {
      const methods = Object.keys(api.paths[p]).filter((m) => ['get', 'post', 'put', 'delete', 'patch'].includes(m));
      methods.forEach((m) => {
        const ep = api.paths[p][m];
        const tag = ep.tags ? ep.tags[0] : 'Untagged';
        console.log(`   ${m.toUpperCase().padEnd(7)} ${p.padEnd(40)} [${tag}]`);
      });
    });

    console.log('\n✨ API validation complete!');
  } catch (err) {
    console.error('❌ API validation failed:');
    console.error(err.message);
    process.exit(1);
  }
}

validateAPI();


