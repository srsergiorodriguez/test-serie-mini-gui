const config = {
  "subtitle":"Un sistema para mini colecciones digitales",
  "credits":"Por Sergio Rodríguez Gómez",
  "copyright":"Todos los derechos reservados, 2025",
  "title":"Serie Mini",
  "lang":"es",
  "base":"https://srsergiorodriguez.github.io",
  "pages":{
    "metadataToIndex":["label"],
    "iiifViewer":true,
    "metadataToShow":[{
        "key":"label",
        "label":"Label",
        "type":"text"
      },{
        "key":"autor",
        "label":"Autor",
        "type":"text"
      },{
        "key":"fecha",
        "label":"Fecha",
        "type":"text"
      }]
  },
  "localPort":"5173",
  "baseurl":"/test-serie-mini-gui"
};

export default config;