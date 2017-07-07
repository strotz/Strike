import jenkins.model.*
 
if (args.length != 1 ) {
  println "Error on arguments!"
}
def slaveName  = args[0] ?: 'slave_name'
for (aSlave in hudson.model.Hudson.instance.slaves) {
  if (aSlave.name == slaveName) println aSlave.getComputer().getJnlpMac() 
}
