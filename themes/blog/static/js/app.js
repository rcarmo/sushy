var source = new EventSource("/events");

source.addEventListener('error', function(e) {
    if (e.readyState == EventSource.CLOSED) {
        console.log("Server down")
    }
    else if( e.readyState == EventSource.OPEN) {
        console.log("Connecting...")
    }
}, false);

source.addEventListener('tick', function(e) {
  console.log(e.data);
}, false);
source.addEventListener('indexing', function(e) {
  console.log(e.data);
}, false);
