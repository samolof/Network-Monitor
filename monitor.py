 import sys, os , pxssh, re , commands, sqlite3, time
 host_file = 'hosts.txt'
 error_file = '/tmp/error.log'
 dbase  = "monitor.db"
 dbtable = "monitor"
 
 def initialize_database():
   #if database exists return
   if os.path.isfile(dbase):
     conn = sqlite3.connect(dbase,timeout=20)        
     return conn
   # else create table and trigger to insert timestamps with every entry    
   conn = sqlite3.connect(dbase)
   c = conn.cursor()     
   c.execute("create table monitor ( mydata TEXT, timestamp DATETIME)")
   c.execute("CREATE TRIGGER insert_time AFTER INSERT ON monitor BEGIN UPDATE monitor SET timestamp =    
      DATETIME('NOW') WHERE rowid = new.rowid;  END;")
   c.execute("CREATE TRIGGER del_old_recs BEFORE INSERT ON monitor BEGIN DELETE FROM monitor WHERE timestamp <
      DATETIME('now','-1month'); END;")    
   return conn
 def dox(s, sendln, pattern):    
   s.sendline(sendln)
   if s.prompt():        
     return re.search(pattern, s.before).group(1)    
   return 'NA'
 def monitor(host, ports, dbase, errfile, datestamp ):
   cursor = dbase.cursor()    
   flags= '-T4 -oG /dev/stdout' 
   nmap_res = commands.getoutput('nmap -p %s %s %s' % (",".join(ports), flags, host))    
   host_res =     
   try:
     cursor.execute("insert into monitor (mydata) values ('%s')" % (nmap_res,) )
     dbase.commit()
     s= pxssh.pxssh()
     if s.login(host, 'admin', 'passwd',login_timeout=6) == True:            
      uptime = dox(s,'uptime', r'(\d{1,2}:\d{2}:?\d{0,2})')
      memfree = dox(s,'cat /proc/meminfo', r'MemFree:\s+(\d+)') 
      ipaddr = commands.getoutput('host %s | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"' % host)
      host_res = "Ihost: %s  Uptime: %s FreeMem: %s  %s" % (ipaddr, uptime, memfree, datestamp)
      cursor.execute("insert into monitor (mydata) values (\"%s\")" % (host_res,) )
      dbase.commit()                
      s.logout()
      s.close()                    
   except Exception, e:
     errfile.write(" %s: %s %s\n" % (host, unicode(e), datestamp) )             
 def main():    
    datestamp = commands.getoutput('date')    
    errfile = open(error_file, 'w')
    dbase_obj = initialize_database()    
    while True:
     for line in open(host_file):
      all = line.strip('\n').split(',')                
      if os.fork() == 0:                                                
       monitor(all[0], all[1:] ,dbase_obj, errfile, datestamp)                         
       dbase_obj.close()
       errfile.close()
       os._exit(0)
     time.sleep(86400)
 main()

