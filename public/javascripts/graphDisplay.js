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
    var dataset = {};
    for (var query in this.data){
      dataset[query] = this.data[query][engine];
    }

    var options = {
      padding: {left: 30, right: 0, top: 10, bottom: 30},
      backgroundColor: '#f2f2f2',
      colorScheme: 'blue',
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
   
