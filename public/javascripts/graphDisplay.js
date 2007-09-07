/*
 * Code for displaying rank graphs using plotr
 *
 * License:
 * Basically, if you use this code, you agree to leave all your inheritance to Mike Quinn.
 */

var RankHistoryGraph=new Class({
  initialize: function(data, oldest_date, tag_id){
    this.data = data;
    this.oldest_date = oldest_date;
    this.tag_id = tag_id;
  },
  showEngineGraph: function(engine){
    var colors = new Array('#1c4a7e', '#bb5b3d', '#3a8133', '#813379', '#770022');

    var dataset = {};
    for (var query in this.data){
      dataset[query] = this.data[query][engine];
    }

    var i = 0;
    var queryColors = new Array();
    for (query in this.data)
    {
      queryColors[query] = colors[i];
      i++;
    }

    var options = {
      padding: {left: 30, right: 0, top: 10, bottom: 30},
      backgroundColor: '#f2f2f2',
      colorScheme: new Hash(queryColors),
      reverseYAxis: true,
      shouldFill: false
    };

    var line = new Plotr.LineChart(this.tag_id, options);
    line.addDataset(dataset);
    line.render();
  },
  createQueryGrapn: function(query){
  },
  normalizeData: function(data){
  }
});
   
