---
title: "RESTful API"
date: 2018-02-13T13:56:12-05:00
showDate: true
draft: false
tags: ["spring","分布式"]
---

REST这个词，是Roy Thomas Fielding在他2000年的博士论文——《Architectural Styles and the Design of Network-based Software Architectures》中提出的。Fielding是HTTP协议（1.0版和1.1版）的主要设计者、Apache服务器软件的作者之一、Apache基金会的第一任主席。所以，他的这篇论文一经发表，就引起了关注，并且立即对互联网开发产生了深远的影响。

Fielding将他对互联网软件的架构原则，定名为REST，即Representational State Transfer的缩写。

## 1 基本概念

### 1.1 简介

REST，即我们常说的RESTful，全称是Representational State Transfer。一般被翻译为**表现层状态转移**。

如果一个架构符合REST原则，就称它为RESTful架构。

要理解RESTful架构，最好的方法就是去理解Representational State Transfer这个词组到底是什么意思，它的每一个词代表了什么涵义。

- 资源Resources

  REST的名称"表现层状态转化"中，省略了主语。"表现层"其实指的是**"资源"（Resources）的"表现层"**。

  所谓"资源"，就是网络上的一个实体，或者说是网络上的一个具体信息。它可以是一段文本、一张图片、一首歌曲、一种服务，总之就是一个具体的实在。你可以用一个URI（统一资源定位符）指向它，每种资源对应一个特定的URI。要获取这个资源，访问它的URI就可以，因此URI就成了每一个资源的地址或独一无二的识别符。


- 表现层Representation

  "资源"是一种信息实体，它可以有多种外在表现形式。我们把"资源"具体呈现出来的形式，叫做它的"表现层"（Representation）。

  比如，文本可以用txt格式表现，也可以用HTML格式、XML格式、JSON格式表现，甚至可以采用二进制格式；图片可以用JPG格式表现，也可以用PNG格式表现。

  URI只代表资源的实体，不代表它的形式。严格地说，有些网址最后的".html"后缀名是不必要的，因为这个后缀名表示格式，属于"表现层"范畴，而URI应该只代表"资源"的位置。它的具体表现形式，应该在HTTP请求的头信息中用Accept和Content-Type字段指定，这两个字段才是对"表现层"的描述。

- 状态转移State Transfer

  访问一个网站，就代表了客户端和服务器的一个互动过程。在这个过程中，势必涉及到数据和状态的变化。

  HTTP协议，是一个无状态协议。这意味着，所有的状态都保存在服务器端。因此，如果客户端想要操作服务器，必须通过某种手段，让服务器端发生"状态转移"（State Transfer）。而这种转移是建立在表现层之上的，所以就是"表现层状态转移"。

  HTTP协议里面，四个表示操作方式的动词：GET、POST、PUT、DELETE。它们分别对应四种基本操作：GET用来获取资源，POST用来新建资源（也可以用于更新资源），PUT用来更新资源，DELETE用来删除资源。


### 1.2 http的幂等性

在HTTP/1.1规范中幂等性的定义是：

> Methods can also have the property of "idempotence" in that (aside from error or expiration issues) the side-effects of N > 0 identical requests is the same as for a single request.

从定义上看，HTTP方法的幂等性是指一次和多次请求某一个资源应该具有同样的副作用。幂等性属于语义范畴，正如编译器只能帮助检查语法错误一样，HTTP规范也没有办法通过消息格式等语法手段来定义它，这可能是它不太受到重视的原因之一。但实际上，幂等性是分布式系统设计中十分重要的概念，而HTTP的分布式本质也决定了它在HTTP中具有重要地位。

我们先从一个例子说起，假设有一个从账户取钱的远程API（可以是HTTP的，也可以不是），我们暂时用类函数的方式记为:

```java
bool withdraw(account_id, amount)
```

withdraw的语义是从account_id对应的账户中扣除amount数额的钱；如果扣除成功则返回true，账户余额减少amount；如果扣除失败则返回false，账户余额不变。

值得注意的是：和本地环境相比，我们不能轻易假设分布式环境的可靠性。一种典型的情况是withdraw请求已经被服务器端正确处理，但服务器端的返回结果由于网络等原因被掉丢了，导致客户端无法得知处理结果。如果是在网页上，一些不恰当的设计可能会使用户认为上一次操作失败了，然后刷新页面，这就导致了withdraw被调用两次，账户也被多扣了一次钱。

这个问题的解决方案一是采用分布式事务，通过引入支持分布式事务的中间件来保证withdraw功能的事务性。分布式事务的优点是对于调用者很简单，复杂性都交给了中间件来管理。缺点则是一方面架构太重量级，容易被绑在特定的中间件上，不利于异构系统的集成；另一方面分布式事务虽然能保证事务的ACID性质，而但却无法提供性能和可用性的保证。

另一种更轻量级的解决方案是幂等设计。我们可以通过一些技巧把withdraw变成幂等的，比如:

```java
int create_ticket() 
bool idempotent_withdraw(ticket_id, account_id, amount)
```

create_ticket的语义是获取一个服务器端生成的唯一的处理号ticket_id，它将用于标识后续的操作。idempotent_withdraw和withdraw的区别在于关联了一个ticket_id，一个ticket_id表示的操作至多只会被处理一次，每次调用都将返回第一次调用时的处理结果。这样，idempotent_withdraw就符合幂等性了，客户端就可以放心地多次调用。

基于幂等性的解决方案中一个完整的取钱流程被分解成了两个步骤：1.调用create_ticket()获取ticket_id；2.调用idempotent_withdraw(ticket_id, account_id, amount)。虽然create_ticket不是幂等的，但在这种设计下，它对系统状态的影响可以忽略，加上idempotent_withdraw是幂等的，所以任何一步由于网络等原因失败或超时，客户端都可以重试，直到获得结果。

和分布式事务相比，幂等设计的优势在于它的轻量级，容易适应异构环境，以及性能和可用性方面。在某些性能要求比较高的应用，幂等设计往往是唯一的选择。

HTTP协议本身是一种面向资源的应用层协议，但对HTTP协议的使用实际上存在着两种不同的方式：一种是RESTful的，它把HTTP当成应用层协议，比较忠实地遵守了HTTP协议的各种规定；另一种是SOA的，它并没有完全把HTTP当成应用层协议，而是把HTTP协议作为了传输层协议，然后在HTTP之上建立了自己的应用层协议。

- HTTP GET方法用于获取资源，不应有副作用，所以是幂等的。
- HTTP DELETE方法用于删除资源，有副作用，但它应该满足幂等性。
- POST请求会在服务器端创建两份资源，它们具有不同的URI；所以，POST方法不具备幂等性。
- 对同一URI进行多次PUT的副作用和一次PUT是相同的；因此，PUT方法具有幂等性。

### 1.3 设计指南

这部分内容主要参考阮一峰老师的[《RESTful API 设计指南》](http://www.ruanyifeng.com/blog/2014/05/restful_api.html)，为了方便以后查阅，搬运过来。

##### 一、协议

API与用户的通信协议，总是使用[HTTPs协议](http://www.ruanyifeng.com/blog/2014/02/ssl_tls.html)。

##### 二、域名

应该尽量将API部署在专用域名之下。

 ```
 https://api.example.com
 ```

如果确定API很简单，不会有进一步扩展，可以考虑放在主域名下。

```
 https://example.org/api/
```

##### 三、版本（Versioning）

应该将API的版本号放入URL。

```
https://api.example.com/v1/
```

另一种做法是，将版本号放在HTTP头信息中，但不如放入URL方便和直观。[Github](https://developer.github.com/v3/media/#request-specific-version)采用这种做法。

##### 四、路径（Endpoint）

路径又称"终点"（endpoint），表示API的具体网址。

在RESTful架构中，每个网址代表一种资源（resource），所以网址中不能有动词，只能有名词，而且所用的名词往往与数据库的表格名对应。一般来说，数据库中的表都是同种记录的"集合"（collection），所以API中的名词也应该使用复数。

举例来说，有一个API提供动物园（zoo）的信息，还包括各种动物和雇员的信息，则它的路径应该设计成下面这样。

- https://api.example.com/v1/zoos
- https://api.example.com/v1/animals
- https://api.example.com/v1/employees

##### 五、HTTP动词

对于资源的具体操作类型，由HTTP动词表示。

常用的HTTP动词有下面五个（括号里是对应的SQL命令）。

- GET（SELECT）：从服务器取出资源（一项或多项）。
- POST（CREATE）：在服务器新建一个资源。
- PUT（UPDATE）：在服务器更新资源（客户端提供改变后的完整资源）。
- PATCH（UPDATE）：在服务器更新资源（客户端提供改变的属性）。
- DELETE（DELETE）：从服务器删除资源。

还有两个不常用的HTTP动词。

- HEAD：获取资源的元数据。
- OPTIONS：获取信息，关于资源的哪些属性是客户端可以改变的。

下面是一些例子。

- GET /zoos：列出所有动物园
- POST /zoos：新建一个动物园
- GET /zoos/ID：获取某个指定动物园的信息
- PUT /zoos/ID：更新某个指定动物园的信息（提供该动物园的全部信息）
- PATCH /zoos/ID：更新某个指定动物园的信息（提供该动物园的部分信息）
- DELETE /zoos/ID：删除某个动物园
- GET /zoos/ID/animals：列出某个指定动物园的所有动物
- DELETE /zoos/ID/animals/ID：删除某个指定动物园的指定动物

##### 六、过滤信息（Filtering）

如果记录数量很多，服务器不可能都将它们返回给用户。API应该提供参数，过滤返回结果。

下面是一些常见的参数。

- ?limit=10：指定返回记录的数量
- ?offset=10：指定返回记录的开始位置。
- ?page=2&per_page=100：指定第几页，以及每页的记录数。
- ?sortby=name&order=asc：指定返回结果按照哪个属性排序，以及排序顺序。
- ?animal_type_id=1：指定筛选条件

参数的设计允许存在冗余，即允许API路径和URL参数偶尔有重复。比如，GET /zoo/ID/animals 与 GET /animals?zoo_id=ID 的含义是相同的。

##### 七、状态码（Status Codes）

服务器向用户返回的状态码和提示信息，常见的有以下一些（方括号中是该状态码对应的HTTP动词）。

- 200 OK - [GET]：服务器成功返回用户请求的数据，该操作是幂等的（Idempotent）。
- 201 CREATED - [POST/PUT/PATCH]：用户新建或修改数据成功。
- 202 Accepted - [*]：表示一个请求已经进入后台排队（异步任务）
- 204 NO CONTENT - [DELETE]：用户删除数据成功。
- 400 INVALID REQUEST - [POST/PUT/PATCH]：用户发出的请求有错误，服务器没有进行新建或修改数据的操作，该操作是幂等的。
- 401 Unauthorized - [*]：表示用户没有权限（令牌、用户名、密码错误）。
- 403 Forbidden - [*] 表示用户得到授权（与401错误相对），但是访问是被禁止的。
- 404 NOT FOUND - [*]：用户发出的请求针对的是不存在的记录，服务器没有进行操作，该操作是幂等的。
- 406 Not Acceptable - [GET]：用户请求的格式不可得（比如用户请求JSON格式，但是只有XML格式）。
- 410 Gone -[GET]：用户请求的资源被永久删除，且不会再得到的。
- 422 Unprocesable entity - [POST/PUT/PATCH] 当创建一个对象时，发生一个验证错误。
- 500 INTERNAL SERVER ERROR - [*]：服务器发生错误，用户将无法判断发出的请求是否成功。

状态码的完全列表参见[这里](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)。

##### 八、错误处理（Error handling）

如果状态码是4xx，就应该向用户返回出错信息。一般来说，返回的信息中将error作为键名，出错信息作为键值即可。

```
{
    error: "Invalid API key"
}
```

##### 九、返回结果

针对不同操作，服务器向用户返回的结果应该符合以下规范。

- GET /collection：返回资源对象的列表（数组）
- GET /collection/resource：返回单个资源对象
- POST /collection：返回新生成的资源对象
- PUT /collection/resource：返回完整的资源对象
- PATCH /collection/resource：返回完整的资源对象
- DELETE /collection/resource：返回一个空文档

##### 十、Hypermedia API

RESTful API最好做到Hypermedia，即返回结果中提供链接，连向其他API方法，使得用户不查文档，也知道下一步应该做什么。

比如，当用户向api.example.com的根目录发出请求，会得到这样一个文档。

```
{"link": {
  "rel":   "collection https://www.example.com/zoos",
  "href":  "https://api.example.com/zoos",
  "title": "List of zoos",
  "type":  "application/vnd.yourformat+json"
}}
```

上面代码表示，文档中有一个link属性，用户读取这个属性就知道下一步该调用什么API了。rel表示这个API与当前网址的关系（collection关系，并给出该collection的网址），href表示API的路径，title表示API的标题，type表示返回类型。

Hypermedia API的设计被称为[HATEOAS](http://en.wikipedia.org/wiki/HATEOAS)。Github的API就是这种设计，访问[api.github.com](https://api.github.com/)会得到一个所有可用API的网址列表。

```
{
  "current_user_url": "https://api.github.com/user",
  "authorizations_url": "https://api.github.com/authorizations",
  // ...
}
```

从上面可以看到，如果想获取当前用户的信息，应该去访问[api.github.com/user](https://api.github.com/user)，然后就得到了下面结果。

```
{
  "message": "Requires authentication",
  "documentation_url": "https://developer.github.com/v3"
}
```

上面代码表示，服务器给出了提示信息，以及文档的网址。

##### 十一、其他

（1）API的身份认证应该使用[OAuth 2.0](http://www.ruanyifeng.com/blog/2014/05/oauth_2_0.html)框架。

（2）服务器返回的数据格式，应该尽量使用JSON，避免使用XML。

## 2 spring boot实践

### 2.1 注解

在spring boot中提供了如下几个注解来快速编写restful api

- `@Controller`：修饰class，用来创建处理http请求的对象 

  `@RestController`：Spring4之后加入的注解，原来在`@Controller`中返回json需要`@ResponseBody`来配合，如果直接用`@RestController`替代`@Controller`就不需要再配置`@ResponseBody`，默认返回`json`格式。 

- `@RequestMapping`：配置url映射 

  `@GetMapping` `@PostMapping` `@PutMapping` `@DeleteMapping`：相当于`@RequestMapping`中的Method的配置。

- `@PathVariable` `@ModelAttribute` `@RequestParam`：参数绑定注解

### 2.2 具体代码

首先创建一个实体类

```java
// lombok的注解，自动生成get和set方法
@Data
public class User {
    private Integer id;
    private String name;
}
```

然后创建处理的repository

```java
@Repository
public class UserRepository {

    /**
     * 不使用数据库，采用map的方式来存数据
     */
    private final Map<Integer, User> userMap = new ConcurrentHashMap<>(16);

    /**
     * id生成器
     */
    private final static AtomicInteger idGen = new AtomicInteger();

    public boolean save(User user) {
        Integer id = idGen.getAndIncrement();
        user.setId(id);
        return userMap.put(id, user) == null;
    }

    public Collection<User> findAll() {
        return userMap.values();
    }

    public User findById(Integer id){
        return userMap.get(id);
    }

    public boolean delete(Integer id){
        return userMap.remove(id) == null;
    }

}
```

最后是controller

```java
@RestController
@CommonsLog//lombok的注解，生成log对象
public class UserController {
    private final UserRepository userRepository;

    @Autowired
    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @PostMapping("/set")
    public User save(@RequestParam String name) {
        User user = new User();
        user.setName(name);
        if (userRepository.save(user)) {
            log.info("success: " + user.toString());
        }
        return user;
    }

    @GetMapping("/get/all")
    public Collection<User> getAll() {
        return userRepository.findAll();
    }

    @GetMapping("/get/{id}")
    public User getId(@PathVariable Integer id) {
        return userRepository.findById(id);
    }

    @PutMapping("/put")
    public User put(@RequestParam String name) {
        User user = new User();
        user.setName(name);
        userRepository.save(user);
        return user;
    }

    @DeleteMapping("/delete/{id}")
    public Boolean delete(@PathVariable Integer id) {
        return userRepository.delete(id);
    }

}
```

### 2.3 测试

可以通过postman来进行测试。

也可以通过编写单元测试代码的方式对controller进行测试。

新版本的spring boot的测试使用的注解是：

- @SpringBootTest
- @AutoConfigureMockMvc：自动配置MockMvc

```java
@RunWith(SpringRunner.class)
@SpringBootTest
@AutoConfigureMockMvc
public class MyAppApplicationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Test
    public void saves() {
        User user = new User();
        user.setName("zhu");
        assertTrue("true", userRepository.save(user));
    }

    @Test
    public void controllerTest() throws Exception {
        RequestBuilder request = null;

        request = get("/get/all");
        mockMvc.perform(request)
                .andExpect(status().isOk())
                .andExpect(content().string("[]"));

        request = post("/set").param("name", "zhu");
        mockMvc.perform(request)
                .andExpect(status().isOk());
    }
}
```

## 3 构建RESTful API文档

我们构建RESTful API的目的通常都是由于多终端的原因，这些终端会共用很多底层业务逻辑，因此我们会抽象出这样一层来同时服务于多个移动端或者Web前端。

这样一来，我们的RESTful API就有可能要面对多个开发人员或多个开发团队：IOS开发、Android开发或是Web开发等。为了减少与其他团队平时开发期间的频繁沟通成本，传统做法我们会创建一份RESTful API文档来记录所有接口细节，然而这样的做法有以下几个问题：

- 由于接口众多，并且细节复杂（需要考虑不同的HTTP请求类型、HTTP头部信息、HTTP请求内容等），高质量地创建这份文档本身就是件非常吃力的事，下游的抱怨声不绝于耳。
- 随着时间推移，不断修改接口实现的时候都必须同步修改接口文档，而文档与代码又处于两个不同的媒介，除非有严格的管理机制，不然很容易导致不一致现象。

为了解决上面这样的问题，接下来将介绍RESTful API的重磅好伙伴Swagger2，它可以轻松的整合到Spring Boot中，并与Spring MVC程序配合组织出强大RESTful API文档。它既可以减少我们创建文档的工作量，同时说明内容又整合入实现代码中，让维护文档和修改代码整合为一体，可以让我们在修改代码逻辑的同时方便的修改文档说明。另外Swagger2也提供了强大的页面测试功能来调试每个RESTful API。

### 3.1 pom依赖

```xml
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger2</artifactId>
    <version>2.4.0</version>
</dependency>
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger-ui</artifactId>
    <version>2.4.0</version>
</dependency>
```

### 3.2 创建配置类

```java
@Configuration
@EnableSwagger2
public class Swagger2Config {
    @Bean
    public Docket createRestApi() {
        return new Docket(DocumentationType.SWAGGER_2)
                .apiInfo(apiInfo())
                .select()
                .apis(RequestHandlerSelectors.basePackage("com.zzf.myapp"))
                .paths(PathSelectors.any())
                .build();
    }

    private ApiInfo apiInfo() {
        return new ApiInfoBuilder()
                .title("Spring Boot中使用Swagger2构建RESTful APIs")
                .description("这一个是测试")
                .termsOfServiceUrl("https://github.com/zhenfeng-zhu")
                .contact(new Contact("Lucas", "https://github.com/zhenfeng-zhu", "codeless98@163.com"))
                .version("1.0")
                .build();
    }
}
```

如上代码所示，通过`@Configuration`注解，让Spring来加载该类配置。再通过`@EnableSwagger2`注解来启用`Swagger2`。

再通过`createRestApi`函数创建`Docket`的`Bean`之后，apiInfo()用来创建该Api的基本信息（这些基本信息会展现在文档页面中）。select()函数返回一个`ApiSelectorBuilder`实例用来控制哪些接口暴露给Swagger来展现，本例采用指定扫描的包路径来定义，`Swagger`会扫描该包下所有`Controller`定义的`API`，并产生文档内容（除了被`@ApiIgnore`指定的请求）。

### 3.3 改造UserController类

在完成了上述配置后，其实已经可以生产文档内容，但是这样的文档主要针对请求本身，而描述主要来源于函数等命名产生，对用户并不友好，我们通常需要自己增加一些说明来丰富文档内容。如下所示，我们通过@ApiOperation注解来给API增加说明、通过@ApiImplicitParams、@ApiImplicitParam注解来给参数增加说明。

```java
@RestController
@CommonsLog//lombok的注解，生成log对象
public class UserController {
    @Autowired
    private UserRepository userRepository;


    @ApiOperation(value = "设置用户", notes = "设置用户")
    @ApiImplicitParam(name = "name", value = "user的用户名", required = true)
    @PostMapping("/set")
    public User save(@RequestParam(value = "name") String name) {
        User user = new User();
        user.setName(name);
        if (userRepository.save(user)) {
            log.info("success: " + user.toString());
        }
        return user;
    }

    @ApiOperation(value = "获取所用用户", notes = "获取所用用户")
    @GetMapping("/get/all")
    public Collection<User> getAll() {
        return userRepository.findAll();
    }

    @ApiOperation(value = "通过id查找用户")
    @ApiImplicitParam(name = "id", value = "用户的id", dataType = "int", required = true)
    @GetMapping("/get/{id}")
    public User getId(@PathVariable Integer id) {
        return userRepository.findById(id);
    }

    @ApiOperation(value = "put方法测试")
    @ApiImplicitParam(name = "id", value = "用户的id", required = true)
    @PutMapping("/put")
    public User put(@RequestParam String name) {
        User user = new User();
        user.setName(name);
        userRepository.save(user);
        return user;
    }

    @ApiOperation(value = "通过id删除用户")
    @ApiImplicitParam(name = "id", value = "用户的id", required = true)
    @DeleteMapping("/delete/{id}")
    public Boolean delete(@PathVariable Integer id) {
        return userRepository.delete(id);
    }

}
```

### 3.4 访问swagger-ui

完成上述代码添加上，启动Spring Boot程序，访问：http://localhost:8080/swagger-ui.html。

相比为这些接口编写文档的工作，我们增加的配置内容是非常少而且精简的，对于原有代码的侵入也在忍受范围之内。因此，在构建RESTful API的同时，加入swagger来对API文档进行管理，是个不错的选择。

## 4 参考资料

阮一峰的文章[《理解RESTful架构》](http://www.ruanyifeng.com/blog/2011/09/restful.html)

小马哥的spring boot系列[《Java 微服务实践 - Spring Boot 系列（三）Web篇（中）》](https://segmentfault.com/l/1500000009767025)

程序员DD的spring boot系列文章[Spring Boot中使用Swagger2构建强大的RESTful API文档 ](http://blog.didispace.com/springbootswagger2/)

