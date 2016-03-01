# weaver-sdk-js
Weaver SDK for JavaScript

## API

### Class: Weaver
- weaver.entity(data, type, id)
- weaver.load(id, {eagerness})

### Class: Entity

##### Read
- entity.id()
- entity.type()
- entity.links()
- entity.values()
- entity.isFetched({eagerness})

##### Sync
- entity.fetch({eagerness})
- entity.push(key, value)
- entity.delete()


## Examples

##### Creating a new Weaver instance
```javascript
weaver = new Weaver('https://weaver-server.herokuapp.com');
```

##### Creating an entity
```javascript
john = weaver.entity({name: 'John Doe', age: 27, male: true});
```

##### Loading an entity
```javascript
weaver.load('cil9cvoae00003k6mz1mvt3gz', {eagerness: 1}).then(function(entity){
  lisa = entity;
});
```

##### Fetching entity
```javascript
john.fetch({eagerness: 3});
```

##### Updating entity
```javascript
john.color = 'Red';
john.push('color');
```

###### or
```javascript
john.push('color', 'Red');
```

##### Linking to another entity
```javascript
john.friend = lisa;
john.push('friend');
```

###### or
```javascript
john.push('friend', lisa);
```


## TODO
- rename fetched to incomplete
- repository weaver under $
- refactor
- restructure tests

## Future work
- paging
- reverse relations
- auth
