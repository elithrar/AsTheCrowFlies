// Offline adapter around the pinned wow.export WDC reader. No app, CASC, key or network modules execute.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),crypto=require('node:crypto');
const base=path.resolve(__dirname,'../../task-2'),src=path.join(base,'tools/wow.export/src/js'),stage=path.resolve(__dirname,'../.work');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const cache=new Map();let current;
const partialMap=process.argv.includes('--partial-map');
const skyOnly=process.argv.includes('--sky');
function load(rel){
 if(cache.has(rel))return cache.get(rel);
 const file=path.join(src,rel),mod={exports:{}};
 const req=name=>{
  if(['util','path','assert','crypto','zlib'].includes(name))return require(name);
  if(name==='fs')return {promises:new Proxy({},{get(){throw Error('Filesystem API unavailable to parser')}})};
  if(name==='webp-wasm')return {};
  if(name==='../log')return {write(){}};
  if(name==='../core')return {view:{casc:{getVirtualFileByName:async()=>BW.from(fs.readFileSync(current))}}};
  if(['../generics','../constants','../casc/export-helper'].includes(name))return new Proxy({},{get(){throw Error('Online/app API disabled: '+name)}});
  const resolved=path.posix.normalize(path.posix.join(path.posix.dirname(rel),name+'.js'));
  if(!['crc32.js','buffer.js','db/DBDParser.js','db/FieldType.js','db/CompressionType.js'].includes(resolved))throw Error('Unapproved import '+resolved);
  return load(resolved);
 };
 let code=fs.readFileSync(file,'utf8').replaceAll('\r\n','\n');
 if(partialMap&&rel==='db/WDCReader.js'){
  const needle='const header = sectionHeaders[sectionIndex];\n\t\t\tconst isNormal';
  if(!code.includes(needle))throw Error('Partial parser source changed');
  code=code.replace(needle,'const header = sectionHeaders[sectionIndex];\n\t\t\tif(header.tactKeyHash!==0n){this.sections[sectionIndex]={header,isEncrypted:true};previousStringTableSize+=header.stringTableSize;continue;}\n\t\t\tconst isNormal');
  const second='const section = this.sections[sectionIndex];\n\t\t\tconst header = section.header;';
  if(!code.includes(second))throw Error('Partial parser accounting source changed');
  code=code.replace(second,'const section = this.sections[sectionIndex];\n\t\t\tif(section.isEncrypted)continue;\n\t\t\tconst header = section.header;');
 }
 new vm.Script('(function(require,module,exports){'+code+'\n})',{filename:file}).runInThisContext()(req,mod,mod.exports);cache.set(rel,mod.exports);return mod.exports;
}
const BW=load('buffer.js'),DBD=load('db/DBDParser.js'),Reader=load('db/WDCReader.js');
async function run(){
 fs.mkdirSync(path.join(stage,'tables'),{recursive:true});
 for(const [name,id] of (skyOnly?[['LightSkybox',1308501],['LightParams',1334669],['Light',1375579],['LightData',1375580]]:[['TaxiNodes',1068100],['TaxiPath',1067802],['TaxiPathNode',1000437],['UiMap',1957206],['UiMapAssignment',1957219]])){
  if(partialMap&&name!=='Map')continue;
  current=partialMap?path.join(stage,'partial/Map.readable-prefix.bin'):path.join(stage,'raw',id+'.bin');if(!fs.existsSync(current)){console.log(name,'missing');continue;}
  const data=fs.readFileSync(current),dbd=fs.readFileSync(path.join(base,'tools/WoWDBDefs/definitions',name+'.dbd'));
  const reader=new Reader(name+'.db2');let schema;
  reader.loadSchema=async layout=>{
   const parser=new DBD(BW.from(dbd));
   const candidates=[...parser.entries].filter(e=>e.layoutHashes?.includes?.(layout)||e.layoutHashes?.has?.(layout));
   schema=parser.getStructure('1.60.1.70338',layout);if(!schema)throw Error('Unknown schema');
   if(!schema.layoutHashes.has(layout) || !schema.builds.has('1.60.1.70338'))throw Error('Layout/build not explicitly matched: '+layout);
   reader.layout=layout;reader.buildSchemaFromDBDStructure(schema);
  };
  await reader.parse();
  if(!partialMap&&reader.sections.some(s=>s.header.tactKeyHash!==0n))throw Error('Encrypted table section rejected');
  const rows=[...reader.getAllRows().values()];if(rows.length!==reader.size)throw Error('Incomplete table decoding');
  const out={name,fileDataId:id,magic:data.subarray(0,4).toString(),layoutHash:reader.layout,sourceSha256:hash(data),schemaSha256:hash(dbd),schemaCommit:'07d008f28907c00827cacadf2d7c1a40f578b6a3',recordCount:reader.recordCount,sourceRowCount:rows.length,rows};
  if(partialMap){if(rows.length!==71||reader.recordCount!==79)throw Error('Partial Map coverage mismatch');out.coverage={complete:false,sourceRecords:79,readableRecords:71,unreadableRecords:8,reason:'Three encrypted BLTE/WDC sections deliberately untouched'};out.sourceHashScope='readable plaintext prefix only';}
  fs.writeFileSync(path.join(stage,'tables',name+(partialMap?'.partial':'')+'.json'),JSON.stringify(out,(_,v)=>typeof v==='bigint'?Number(v):v,2));console.log(name,out.magic,out.layoutHash,rows.length);
 }
}
run().catch(e=>{console.error(e);process.exit(1)});
