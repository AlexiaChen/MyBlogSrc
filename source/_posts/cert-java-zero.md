---
title: CERT Java编码规范翻译（DCL）
date: 2017-12-15 17:16:53
tags:
    - CERT
    - Java
    - Oracle
---

# 声明

---

本文翻译自[CERT](http://www.cert.org/)(计算机安全应急响应组)提供的Java安全编码规范，与其他规范不一样的是，该规范侧重软件安全的编码规范。翻译不完全逐字段翻译，可能有简化删改。文章分为规则（Rules）和建议（Recommendations）部分。前者是规则，程序员需要遵循的，后者是推荐，意在强烈建议那样做（How）。

为了简化文章子标题，Recommendation用Rec简写。

# 正文

---

## Rule 00. 输入校验和数据卫生处理（IDS）

### IDS00-J. 防止SQL注入

严重等级： 高

- 在用户输入之后和存储数据之前，需要对输入的数据进行校验，如果不这么做，会导致注入攻击。

比如，[CVE-2008-2370](http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2008-2370)这个爆出的漏洞叫描述了这样的一个脆弱性，在Apache tomcat 4.1.0到4.1.47， 5.5.0到5.5.26还有6.0.0到6.0.16都发现了这样的漏洞。

#### 代码样例对比

``` java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
 
class Login {
  public Connection getConnection() throws SQLException {
    DriverManager.registerDriver(new
            com.microsoft.sqlserver.jdbc.SQLServerDriver());
    String dbConnection =
      PropertyManager.getProperty("db.connection");
    // Can hold some value like
    // "jdbc:microsoft:sqlserver://<HOST>:1433,<UID>,<PWD>"
    return DriverManager.getConnection(dbConnection);
  }
 
  String hashPassword(char[] password) {
    // Create hash of password
  }
 
  public void doPrivilegedAction(String username, char[] password)
                                 throws SQLException {
    Connection connection = getConnection();
    if (connection == null) {
      // Handle error
    }
    try {
      String pwd = hashPassword(password);
 
      String sqlString = "SELECT * FROM db_user WHERE username = '"
                         + username +
                         "' AND password = '" + pwd + "'";
      Statement stmt = connection.createStatement();
      ResultSet rs = stmt.executeQuery(sqlString);
 
      if (!rs.next()) {
        throw new SecurityException(
          "User name or password incorrect"
        );
      }
 
      // Authenticated; proceed
    } finally {
      try {
        connection.close();
      } catch (SQLException x) {
        // Forward to handler
      }
    }
  }
}
```
以上的代码用JDBC对一个用户进入系统进行验证，password是char型数组，当然，密码用Hash来保存进数据库了，一般来说，开发者都会这么做，密码禁止明文保存嘛，所以pwd字段显然不会被注入。但是这个代码没有处理username字段，导致用户在输入用户名的时候可以构造非法字符串来进行SQL注入攻击，比如在该字段注入一个validuser' OR '1'='1 。
最终的SQL语句拼接的结果为：

``` sql
SELECT * FROM db_user WHERE username='validuser' OR '1'='1' AND password='<PASSWORD>'
```
这样SQL语句就跳过password的，直接可以获取validuser的相关信息，包括密码。

当然，有点经验的Java程序员可能会这么做，用JDBC提供的一个构建SQL命令的API（PreparedStatement）来处理非信任的数据，于是乎写出以下代码:

``` java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
 
class Login {
  public Connection getConnection() throws SQLException {
    DriverManager.registerDriver(new
            com.microsoft.sqlserver.jdbc.SQLServerDriver());
    String dbConnection =
      PropertyManager.getProperty("db.connection");
    // Can hold some value like
    // "jdbc:microsoft:sqlserver://<HOST>:1433,<UID>,<PWD>"
    return DriverManager.getConnection(dbConnection);
  }
 
  String hashPassword(char[] password) {
    // Create hash of password
  }
 
  public void doPrivilegedAction(
    String username, char[] password
  ) throws SQLException {
    Connection connection = getConnection();
    if (connection == null) {
      // Handle error
    }
    try {
      String pwd = hashPassword(password);
      String sqlString = "select * from db_user where username=" +
        username + " and password =" + pwd;     
      PreparedStatement stmt = connection.prepareStatement(sqlString);
 
      ResultSet rs = stmt.executeQuery();
      if (!rs.next()) {
        throw new SecurityException("User name or password incorrect");
      }
 
      // Authenticated; proceed
    } finally {
      try {
        connection.close();
      } catch (SQLException x) {
        // Forward to handler
      }
    }
  }
}
```
以上的代码看起来对了，但是还是阻止不了SQL注入，还是可以攻击username字段，原因是PreparedStatement使用不正确。正确的写法应该是以下代码，减轻防止了SQL注入：

``` java
public void doPrivilegedAction(
  String username, char[] password
) throws SQLException {
  Connection connection = getConnection();
  if (connection == null) {
    // Handle error
  }
  try {
    String pwd = hashPassword(password);
 
    // Validate username length
    if (username.length() > 8) {
      // Handle error
    }
 
    String sqlString =
      "select * from db_user where username=? and password=?";
    PreparedStatement stmt = connection.prepareStatement(sqlString);
    stmt.setString(1, username);
    stmt.setString(2, pwd);
    ResultSet rs = stmt.executeQuery();
    if (!rs.next()) {
      throw new SecurityException("User name or password incorrect");
    }
 
    // Authenticated; proceed
  } finally {
    try {
      connection.close();
    } catch (SQLException x) {
      // Forward to handler
    }
  }
}
```
以上的代码防止了SQL的注入，同时还禁止了用户输入过长的用户名。用了PreparedStatement类的setXXXX()的方法，会强制进行强类型检查，所以当username出现不合法的符号的时候，直接作出相应处理。


### IDS01-J. 在校验字符串之前先规格化（标准化）字符串

严重等级： 高

- 如果不这样做，可能会导致异常执行非法代码

许多Web应用会使用String来表示校验机制，比如正则表达式校验输入合不合法，校验输入框输入的非法字符串作出相应处理。例如，禁止\<script\> 标签出现在输入框中，防止跨站脚本(XSS)攻击，还有一些黑名单的校验机制也是这么做。

Java中的字符信息是基于Unicode标准的，
- Java SE 6是Unicode 4.0 
- Java SE 7是Unicode 6.0.0 
- Java SE 8是Unicode 6.0.2

所以应用在接收未经过信任的输入String需要在校验之前把String做规范化，规范化在Unicode标准中是非常重要的，因为同样显示出来的String可能底层有不同的二进制表示。

根据Unicode标准[Davis 2008](https://wiki.sei.cmu.edu/confluence/display/java/Rule+AA.+References#RuleAA.References-Davis08), annex #15，Unicode的标准化形式：

> When implementations keep strings in a normalized form, they can be assured that equivalent strings have a unique binary representation.

#### 代码样例对比

``` java
// String s may be user controllable
// \uFE64 is normalized to < and \uFE65 is normalized to > using the NFKC normalization form
String s = "\uFE64" + "script" + "\uFE65";
 
// Validate
Pattern pattern = Pattern.compile("[<>]"); // Check for angle brackets
Matcher matcher = pattern.matcher(s);
if (matcher.find()) {
  // Found black listed tag
  throw new IllegalStateException();
} else {
  // ...
}
 
// Normalize
s = Normalizer.normalize(s, Form.NFKC);
```
以上的代码script字符串在进行正则表达式校验匹配之前显然没有规范化，Normalize放到了校验之后，结果就会导致很可能校验会失败，绕过系统验证了，然后导致XSS。这个规范采用的是KC规范。Normalizer.normalize()方法是把Unicode文本转化为标准的规范格式，这个在[Unicode Standard Annex #15 Unicode Normalization Forms](http://www.unicode.org/reports/tr15/tr15-23.html)中有描述。

解决方案很简单，提前规范化就可以了：

``` java
String s = "\uFE64" + "script" + "\uFE65";
 
// Normalize
s = Normalizer.normalize(s, Form.NFKC);
 
// Validate
Pattern pattern = Pattern.compile("[<>]");
Matcher matcher = pattern.matcher(s);
if (matcher.find()) {
  // Found blacklisted tag
  throw new IllegalStateException();
} else {
  // ...
}
```

### IDS03-J. 不要用log输出未经过处理的用户输入

严重等级：中等

可能会导致敏感信息(不该被人知道的用户名或者密码等)被泄漏，这个条款没多少可以讲解的。

#### 代码样例对比

``` java
if (loginSuccessful) {
  logger.severe("User login succeeded for: " + username);
} else {
  logger.severe("User login failed for: " + username);
}
```

所以用以下两种解决方案就可以了，要么处理相应的用户输入，要么处理log函数:

``` java
public String sanitizeUser(String username) {
  return Pattern.matches("[A-Za-z0-9_]+", username))
      ? username : "unauthorized user";
}

if (loginSuccessful) {
  logger.severe("User login succeeded for: " + sanitizeUser(username));
} else {
  logger.severe("User login failed for: " + sanitizeUser(username));
}
```

``` java
class SanitizedTextLogger extends Logger {
  Logger delegate;
 
  public SanitizedTextLogger(Logger delegate) {
    super(delegate.getName(), delegate.getResourceBundleName());
    this.delegate = delegate;
  }
 
  public String sanitize(String msg) {
    Pattern newline = Pattern.compile("\n");
    Matcher matcher = newline.matcher(msg);
    return matcher.replaceAll("\n  ");
  }
 
  public void severe(String msg) {
    delegate.severe(sanitize(msg));
  }
 
  // .. Other Logger methods which must also sanitize their log messages
}

Logger sanLogger = new SanitizedTextLogger(logger);
 
if (loginSuccessful) {
  sanLogger.severe("User login succeeded for: " + username);
} else {
  sanLogger.severe("User login failed for: " + username);
}
```

### IDS04-J. 安全的从ZipInputStream中抽取文件

严重等级：低

这个条款的细节要掌握比较难。

Java提供java.util.zip包来处理zip兼容的数据压缩，该包所含的类可以让用户轻松读取，创建，修改ZIP和GZIP压缩文件格式。

当使用java.util.zip.ZipInputStream类来抽取ZIP文件中的Items的时候需要注意一些安全问题。文件名携带的路径可能会直接覆盖系统中的重要文件，这些都需要注意。

第二个关注点就是，解压ZIP文件的过程，很消耗系统资源，可能由于资源的使用过多导致服务拒绝攻击(Dos)，ZIP算法有很高的压缩率，非常占用资源。一个例子就是网络上流传的ZIP炸弹(ZIP Bomb),[42KB大小的ZIP文件](http://www.unforgettable.dk/)包含了上PB级别的信息量。至于怎么做到的，看官网解释:

> The
 file contains 16 zipped files, which again contains 16 zipped files, 
which again contains 16 zipped files, which again contains 16 zipped, 
which again contains 16 zipped files, which contain 1 file, with the 
size of 4.3GB.

这个压缩文件中包含16个压缩文件，这样递归下去有5个层级，也就是16^5=1048576个压缩文件，每个压缩文件里面包含一个4.3GB文件，4.3GB * 1048576 = 4.5PB

所以代码需要限制约束。

#### 代码样例对比

``` java
static final int BUFFER = 512;
// ...
 
public final void unzip(String filename) throws java.io.IOException{
  FileInputStream fis = new FileInputStream(filename);
  ZipInputStream zis = new ZipInputStream(new BufferedInputStream(fis));
  ZipEntry entry;
  try {
    while ((entry = zis.getNextEntry()) != null) {
      System.out.println("Extracting: " + entry);
      int count;
      byte data[] = new byte[BUFFER];
      // Write the files to the disk
      FileOutputStream fos = new FileOutputStream(entry.getName());
      BufferedOutputStream dest = new BufferedOutputStream(fos, BUFFER);
      while ((count = zis.read(data, 0, BUFFER)) != -1) {
        dest.write(data, 0, count);
      }
      dest.flush();
      dest.close();
      zis.closeEntry();
    }
  } finally {
    zis.close();
  }
}
```
以上代码在未进过检验文件大小的情况下，直接在FileOutputStream的构造器里面传入了Name，可能导致本机计算机资源消耗殆尽。

``` java
static final int BUFFER = 512;
static final int TOOBIG = 0x6400000; // 100MB
// ...
 
public final void unzip(String filename) throws java.io.IOException{
  FileInputStream fis = new FileInputStream(filename);
  ZipInputStream zis = new ZipInputStream(new BufferedInputStream(fis));
  ZipEntry entry;
  try {
    while ((entry = zis.getNextEntry()) != null) {
      System.out.println("Extracting: " + entry);
      int count;
      byte data[] = new byte[BUFFER];
      // Write the files to the disk, but only if the file is not insanely big
      if (entry.getSize() > TOOBIG ) {
         throw new IllegalStateException("File to be unzipped is huge.");
      }
      if (entry.getSize() == -1) {
         throw new IllegalStateException("File to be unzipped might be huge.");
      }
      FileOutputStream fos = new FileOutputStream(entry.getName());
      BufferedOutputStream dest = new BufferedOutputStream(fos, BUFFER);
      while ((count = zis.read(data, 0, BUFFER)) != -1) {
        dest.write(data, 0, count);
      }
      dest.flush();
      dest.close();
      zis.closeEntry();
    }
  } finally {
    zis.close();
  }
}
```
以上检查了抽取的entry大小，作出了相应处理判断，但是没有对抽取的数量做判断，也没有校验文件名，可能会覆盖其他重要的文件，所以最终方案是以下:

``` java
static final int BUFFER = 512;
static final long TOOBIG = 0x6400000; // Max size of unzipped data, 100MB
static final int TOOMANY = 1024;      // Max number of files
// ...
 
private String validateFilename(String filename, String intendedDir)
      throws java.io.IOException {
  File f = new File(filename);
  String canonicalPath = f.getCanonicalPath();
 
  File iD = new File(intendedDir);
  String canonicalID = iD.getCanonicalPath();
   
  if (canonicalPath.startsWith(canonicalID)) {
    return canonicalPath;
  } else {
    throw new IllegalStateException("File is outside extraction target directory.");
  }
}
 
public final void unzip(String filename) throws java.io.IOException {
  FileInputStream fis = new FileInputStream(filename);
  ZipInputStream zis = new ZipInputStream(new BufferedInputStream(fis));
  ZipEntry entry;
  int entries = 0;
  long total = 0;
  try {
    while ((entry = zis.getNextEntry()) != null) {
      System.out.println("Extracting: " + entry);
      int count;
      byte data[] = new byte[BUFFER];
      // Write the files to the disk, but ensure that the filename is valid,
      // and that the file is not insanely big
      String name = validateFilename(entry.getName(), ".");
      if (entry.isDirectory()) {
        System.out.println("Creating directory " + name);
        new File(name).mkdir();
        continue;
      }
      FileOutputStream fos = new FileOutputStream(name);
      BufferedOutputStream dest = new BufferedOutputStream(fos, BUFFER);
      while (total + BUFFER <= TOOBIG && (count = zis.read(data, 0, BUFFER)) != -1) {
        dest.write(data, 0, count);
        total += count;
      }
      dest.flush();
      dest.close();
      zis.closeEntry();
      entries++;
      if (entries > TOOMANY) {
        throw new IllegalStateException("Too many files to unzip.");
      }
      if (total + BUFFER > TOOBIG) {
        throw new IllegalStateException("File being unzipped is too big.");
      }
    }
  } finally {
    zis.close();
  }
}
```

### IDS06-J. 从格式化字符串中排除未经过安全处理的用户输入

严重程度： 中等

未经过信任的数据交织在格式化字符串中容易导致信息泄漏，容易导致服务拒绝攻击(Dos)。

java.io包里面包含的PrintStream类有两个等价的格式化方法：format()和printf()。System.out和System.err是PrintStream的方法，它允许调用标准输出流和标准错误流。使用这两个方法的风险跟C/C++的printf类似。

#### 代码样例对比

``` java
class Format {
  static Calendar c = new GregorianCalendar(1995, GregorianCalendar.MAY, 23);
  public static void main(String[] args) { 
    // args[0] should contain the credit card expiration date
    // but might contain %1$tm, %1$te or %1$tY format specifiers
    System.out.format(
      args[0] + " did not match! HINT: It was issued on %1$terd of some month", c
    );
  }
}
```
以上有注入风险，一旦args[0]输入的是特殊的格式符号，那么就造成了对象c的信息泄漏了，直接就把正确的日期信息打印出来了

所以需要改成以下代码:

``` java
class Format {
  static Calendar c =
    new GregorianCalendar(1995, GregorianCalendar.MAY, 23);
  public static void main(String[] args) { 
    // args[0] is the credit card expiration date
    // Perform comparison with c,
    // if it doesn't match, print the following line
    System.out.format(
      "%s did not match! HINT: It was issued on %terd of some month", 
      args[0], c
    );
  }
}
```
虽然以上代码可能还可以包含特殊的格式符号，但是这样的做法，特殊格式的符号无效了。



