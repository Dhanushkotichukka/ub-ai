const mongoose = require('mongoose');

async function migrate() {
  await mongoose.connect('mongodb+srv://ubmini:UBmini2226@ubmini.gqya3xx.mongodb.net/owlcoder?appName=ubmini');
  const res = await mongoose.model('User', new mongoose.Schema({ isEmailVerified: Boolean }, {strict:false}))
    .updateMany({}, { $set: { isEmailVerified: true } });
  console.log('Migrated existing users:', res);
  await mongoose.disconnect();
}
migrate();
