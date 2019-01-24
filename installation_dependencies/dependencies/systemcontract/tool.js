
var Web3= require('web3');
var config=require('../web3lib/config');
var fs=require('fs');
var BigNumber = require('bignumber.js');
var web3sync = require('../web3lib/web3sync');

if (typeof web3 !== 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  web3 = new Web3(new Web3.providers.HttpProvider(config.HttpProvider));
}

console.log(config);


function getAbi(file){
	var abi=JSON.parse(fs.readFileSync(config.Ouputpath+"./"/*+file+".sol:"*/+file+".abi",'utf-8'));
	//var abi=JSON.parse(fs.readFileSync(config.Ouputpath+"./"+file+".sol:"+file+".abi",'utf-8'));
	return abi;
}

function getAddress(file){
  return (fs.readFileSync(config.Ouputpath+"./"+file+".address",'utf-8'));
  
}

var options = process.argv;
if( options.length < 3 )
{
  console.log('Usage: node tool.js SystemProxy');
  console.log('Usage: node tool.js AuthorityFilter  ');

  console.log('Usage: node tool.js NodeAction all|register|cancel '); 
  console.log('Usage: node tool.js CAAction all|add|remove ');
  console.log('Usage: node tool.js ConfigAction get|set ');
}

var filename=options[2];

var func=options[3];
console.log('Soc File :'+options[2]);
console.log('Func :'+options[3]);

console.log("SystemProxy address " + getAddress("SystemProxy"));

var initializer = {from: config.account,randomid:Math.ceil(Math.random()*100000000)};


var SystemProxy=web3.eth.contract(getAbi("SystemProxy")).at(getAddress("SystemProxy"));



function getAction(filename){
    var address=SystemProxy.getRoute(filename)[0].toString();
    console.log(filename+" address "+address);
    var contract = web3.eth.contract(getAbi(filename));
    return contract.at(address);
    
}



switch (filename){
  
  case "ConfigAction":
  {
    switch(func){
      case "get":
      {
        if( options.length< 5 ){
          console.log("please input key");
          break;
        }
        var key=options[4];
        var instance=getAction("ConfigAction");
        var value=instance.get(key,  initializer);

        if (value[0].length == 0)
          console.log(key+"=Default");
        else if (key == "CAVerify")
          console.log("config :"+key+"="+value[0]);
        else
          console.log(key+"="+parseInt(value[0], 16));
        break;
      }
      case "set":
      {
        if( options.length< 6 ){
            console.log("please input key，value");
          break;
        }
        var key=options[4];
        var value;
        if (key == "CAVerify")
          value=options[5];
        else
          value=parseInt(options[5]).toString(16);
        
        var instance=getAction("ConfigAction");

        var func = "set(string,string)";
        var params = [key,value];
        var receipt = web3sync.sendRawTransaction(config.account, config.privKey, instance.address, func, params);
        if (key == "CAVerify")
          console.log("config :"+key+","+value);
        else
          console.log("config :"+key+","+parseInt(value,16));
       
        break;
      }
      
      default:
        console.log("Mod Error");
        break;
    }
    break;
  }
  case "SystemProxy":
  {
      console.log("-----------------SystemProxy route----------------------")
    
    

    var routelength=SystemProxy.getRouteSize();
    for( var i=0;i<routelength;i++){
        var key=SystemProxy.getRouteNameByIndex(i).toString();
        var route=SystemProxy.getRoute(key);
        console.log(i+" )"+ key+"=>"+route[0].toString()+","+route[1].toString()+","+route[2].toString());
    }
     
     

    break;
  }
 
  case "AuthorityFilter":
  {
        if( options.length< 6 ){
            console.log("please input account、address、function");
            break;
        }
        console.log("origin :"+options[3]);
        console.log("to :"+options[4]);
        console.log("func :"+options[5]);

      var AuthorityFilter=getAction("AuthorityFilter");
      //process(address origin, address from, address to, string func, string input)

      console.log("authority result :" + AuthorityFilter.process(options[3], "", options[4], options[5], ""));

    break;
  }
  case "NodeAction":
  {
     switch(func){
      
      case "all":
      {
          var instance=getAction("NodeAction");
          var len=instance.getNodeIdsLength(initializer);
          console.log("NodeIdsLength= "+len);
          for( var i=0;i<len;i++){
              console.log("----------node "+i+"---------");
              var id=instance.getNodeId(i);
              console.log("id="+id);
              var node=instance.getNode(id);        
              console.log("name="+node[0].toString());
              console.log("agency="+node[1].toString());
              console.log("caHash="+node[2].toString());
              console.log("Idx="+node[3].toString());
              //console.log("blocknumber="+node[4].toString());
          }
          break;
      }
      case "cancelNode":
      case "cancel":
      {
       
        
       if( options.length< 5 ){
          console.log("please input node.json");
          break;
        }
        console.log("node.json="+options[4]);
        var node=JSON.parse(fs.readFileSync(options[4],'utf-8'));

        var instance=getAction("NodeAction");
        var func = "cancelNode(string)";
        var params = [node.id];
        var receipt = web3sync.sendRawTransaction(config.account, config.privKey, instance.address, func, params);

        
        break;
      }
      case "registerNode":
      case "register":
      {
        if( options.length< 5 ){
          console.log("please input node.json");
          break;
        }
        console.log("node.json="+options[4]);
        var node=JSON.parse(fs.readFileSync(options[4],'utf-8'));

        var instance=getAction("NodeAction");
        var func = "registerNode(string,string,string,string)";
        var params = [node.id,node.name,node.agency,node.caHash]; 
        var receipt = web3sync.sendRawTransaction(config.account, config.privKey, instance.address, func, params);


        break;
      }
      default:
      console.log("Func Error"); 
      break;
    }
    break;
  }
  case "CAAction":
  {
     switch(func){
      
      case "all":
      {
          var instance=getAction("CAAction");
          var len=instance.getHashsLength(initializer);
          console.log("HashsLength= "+len);
          for( var i=0;i<len;i++){
              console.log("----------CA "+i+"---------");
              var serial=instance.getHash(i);
              console.log("serial="+serial);
              var ca=instance.get(serial);        
 
              console.log("pubkey="+ca[1].toString());
              console.log("name="+ca[2].toString());
              console.log("blocknumber="+ca[3].toString());
              
          }
          break;
      }
      case "add":
      {
       
       if( options.length< 5 ){
          console.log("ca.json");
          break;
        }
        console.log("ca.json="+options[4]);
        var ca=JSON.parse(fs.readFileSync(options[4],'utf-8'));
         var instance=getAction("CAAction");
        var func = "add(string,string,string)";
        var params = [ca.serial,ca.pubkey,ca.name]; 
        var receipt = web3sync.sendRawTransaction(config.account, config.privKey, instance.address, func, params);

        break;
      }
      
      case "remove":
      {
        if( options.length< 5 ){
          console.log("please input path ： ca.json");
          break;
        }
        console.log("ca.json="+options[4]);
        var ca=JSON.parse(fs.readFileSync(options[4],'utf-8'));

        var instance=getAction("CAAction");
        var func = "remove(string)";
        var params = [ca.serial]; 
        var receipt = web3sync.sendRawTransaction(config.account, config.privKey, instance.address, func, params);

        break;
      }
      default:
      console.log("Func Error"); 
      break;
    }
    break;
  }
  default:
    console.log("Mod Error");
    break;
}
