# iFind Search Portal

This demo is a basic showcase for iFind features, including dominant concepts, proximity, highlighting and result ranking.
Simply start typing and explore your search results. 

Note that the dominant, similar and related concepts widgets illustrate iKnow's unique concept capabilities, whereas classic search solutions would only be able to display individual words or predefined "good" word combinations. For more information about iKnow, check its [open source repo](https://github.com/intersystems/iknow).

## Installation

### Classic

Download the sources and import the `/src` folder into your namespace of choice (compiling them in the process).

```ObjectScript
d $system.OBJ.ImportDir("/path/to/isc-iknow-ifindportal/src/",,"c",,1)
```

### Using ZPM

Coming soon!

```ObjectScript
zpm install iFindPortal
```

## Use

There is no specific setup required. You can simply point the UI to a table with an iFind Analytic index by adding `?t=Your_Table.Name` to the URL. For example: [http://localhost:52773/csp/USER/Demo.SearchPortal.Home.zen?t=My_Package.TheTable] 

Alternatively, you can create a subclass of `Demo.SearchPortal.Home` and override the IFP* class parameters to point to your table and index of choice.

More details on how to set up and use this app can be found in this article on the InterSystems Developer Community: https://community.intersystems.com/post/iknow-demo-apps-part-5-ifind-search-portal
