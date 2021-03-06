'**********************************************************
'**  RedditPurple application
'** initially based off of the DeviantArt example application
'**  in the Roku SDK
'**********************************************************

' ********************************************************************
' ********************************************************************
' ***** Object Constructor
' ********************************************************************
' ********************************************************************

Function CreateMediaRSSConnection()As Object
	rss = {
		port: CreateObject("roMessagePort"),
		http: CreateObject("roUrlTransfer"),
		GetPostList: GetPostList,
		DisplayTopPosts: DisplayTopPosts,
    DisplayTopPostsCustom: DisplayTopPostsCustom,
		DisplayPosts: DisplayPosts,
    ShowKeyboard: ShowKeyboard,
        Reddits:[
                "r/all",
                "r/pics",
                "r/gifs",
                "Enter reddit"
            ]
		}

	return rss
End Function

Sub ShowKeyboard(port as object)
     screen = CreateObject("roKeyboardScreen")
     screen.SetMessagePort(port)
     screen.SetTitle("Search Screen")
     screen.SetText("")
     screen.SetDisplayText("enter reddit name")
     screen.AddButton(1, "finished")
     screen.AddButton(2, "back")
     screen.Show()

     while true
         msg = wait(0, screen.GetMessagePort())
         print "message received"
         if type(msg) = "roKeyboardScreenEvent"
             if msg.isScreenClosed()
                 return
             else if msg.isButtonPressed() then
                 print "Evt:"; msg.GetMessage ();" idx:"; msg.GetIndex()
                 if msg.GetIndex() = 1
                     redditName = screen.GetText()
                     m.DisplayTopPostsCustom(redditName)
                     print "reddit name: "; redditName
                     return
                 endif
             endif
         endif
     end while
End Sub


Function DisplaySetup(port as object)
	screen = CreateObject("roImageCanvas") 'CreateObject("roTextScreen")
	screen.SetMessagePort(port)
	'screen.SetTitle("Reddit")
	'screen.Show()
	return screen
End Function

Sub DisplayTopPosts(index As Integer)
  if index = 3 then
    m.ShowKeyboard(m.port)
  else
  	screen = DisplaySetup(m.port)
  	'screen.SetHeaderText("All")
  	postlist = m.GetPostList("http://www.reddit.com/"+m.Reddits[index]+".json?limit=100")
  	m.DisplayPosts(screen,postlist)
  end if
End Sub

Sub DisplayTopPostsCustom(name As String)
  screen = DisplaySetup(m.port)
  postlist = m.GetPostList("http://www.reddit.com/r/"+name+".json?limit=100")
  m.DisplayPosts(screen,postlist)
End Sub


Function GetPostList(feed_url) As Object

	print "GetPostList: ";feed_url
	m.http.SetUrl(feed_url)

	jsonAsString = m.http.GetToString()

	json = ParseJSON(jsonAsString)
	'print "json";json
	pl = CreateObject("roList")
	for each item in json.data.children
		pl.Push(newPostFromJson(m.http,item))
	next

	return pl

End Function

Function newPostFromXML(http As Object, xml As Object) As Object
  photo = {http:http, xml:xml, GetURL:pGetURL}
  photo.GetTitle=function():return m.xml.title.GetText():end function
  photo.GetCategory=function():return m.xml.category.GetText():end function
  photo.GetDescription=function():return m.xml.description.GetText():end function
  return photo
End Function

Function newPostFromJson(http As Object, json As Object) As Object
  post = {}
  post.title = json.data.title
  post.thumbnail = json.data.thumbnail
  post.selftext = json.data.selftext
  post.url = json.data.url
  post.domain = json.data.domain
  post.nsfw = json.data.over_18
  return post
End Function


Function pGetURL()
	for each c in m.xml.GetNamedElements("media:thumbnail")
		return c@url
	next

	return invalid
End Function


Function createText(text,index,pageNum,x,w)
	bb = CreateObject("roAssociativeArray")
	bb.Text = text
	bb.TextAttrs = {Color:"#FFCCCCCC", Font:"Medium"}
	bb.HAlign = "Left"
	bb.VAlign = "Center"
	bb.Direction = "LeftToRight"
	indy = (index-(6*pageNum))
	yPos = 60+(90*indy)

	bb.TargetRect = {x:x,y:yPos,w:w,h:70}

	return bb
End Function

Function createThumbnail(photo, index, pageNum)
	aa = CreateObject("roAssociativeArray")
    if(photo.nsfw) then
        aa.Text = "NSFW"
        aa.TextAttrs = {Color:"#FFCCCCCC", Font:"Small"}
        aa.HAlign = "Left"
        aa.VAlign = "Center"
        aa.Direction = "LeftToRight"
    else
        aa.url = photo.thumbnail
    endif
	indy = (index-(6*pageNum))
	yPos = 60+(90*indy)

	aa.TargetRect = {x:100,y:yPos,w:70,h:70}

	return aa
End Function



Function GetCanvasItems(photolist,pageNum, x, w)
	itemCount = photolist.Count()
	canvasItems  = CreateObject("roArray", itemCount, true)

	print "pagenum*9: "; pageNum*6

	for i=pageNum*6 to itemCount-1 step +1

			canvasItems.Push(createThumbnail(photolist[i],i,pageNum))
			canvasItems.Push(createText(photolist[i].title,i,pageNum,x,w))
			'print "iterator -- "; i

		i.SetInt(i+1)

	end for

	return canvasItems
End Function

Sub InitCanvas(slideshow,photolist,pageNum, x, w)
	slideshow.SetLayer(0, {Color:"#FF000000", CompositionMode:"Source"})
   	slideshow.SetRequireAllImagesToDraw(true)
   	slideshow.SetLayer(1, GetCanvasItems(photolist,pageNum,x,w))
   	slideshow.SetLayer(2, createText("<--",0,pageNum,x+w+5,50))
   	slideshow.Show()
End Sub

Sub ResetCanvas(slideshow,photolist,position,pageNum,x,w)
	slideshow.ClearLayer(1)
   	slideshow.SetLayer(1, GetCanvasItems(photolist,pageNum,x,w))
   	UpdateArrow(slideshow,position-(pageNum*6),0,x,w)
End Sub

Sub UpdateArrow(slideshow, position,pageNum, x, w)
	slideshow.ClearLayer(2)
    slideshow.SetLayer(2,createText("<--",position-(pageNum*6),0,x+w+5,50))
	slideshow.Show()
End Sub



Sub DisplayPosts(slideshow, photolist)

print "in DisplayPosts"
    'using SetContentList()
	x=190
	w=900

	photoCount = photolist.Count()

   	position=CreateObject("roInt")
	position.SetInt(0)

	pageNum = CreateObject("roInt")
	pageNum.SetInt(0)

   	InitCanvas(slideshow,photolist,pageNum,x,w)

   while(true)
       msg = wait(0,m.port)
       if type(msg) = "roImageCanvasEvent" then
           if (msg.isRemoteKeyPressed()) then
               i = msg.GetIndex()
               print "Key Pressed - " ; msg.GetIndex()

               'up, move arrow up
               if (i = 2) then
                   if(position > 0) then

                   		position.SetInt(position-1)

                   		if(position <= 6*pageNum AND position > 0) then
                   			pageNum.SetInt(pageNum - 1)
                   			ResetCanvas(slideshow,photolist,position,pageNum,x,w)
                   		else
                   			UpdateArrow(slideshow,position,pageNum,x,w)
                   		end if

                   end if
               'down, move arrow down'
               elseif (i = 3) then
               		if(position < photoCount-1) then

               			position.SetInt(position+1)

               			if(position > 6*pageNum + 6) then
               				pageNum.SetInt(pageNum + 1)
               				ResetCanvas(slideshow,photolist,position,pageNum,x,w)
               			else
               				UpdateArrow(slideshow,position,pageNum,x,w)
               			end if

               		end if
               elseif (i=0) then
               		slideshow.close()

               elseif (i=6) then
               	'hit okay button on link, open new window
               		ShowImageScreen(photolist[position])

               else
               	'print "nothing important pressed"
               end if
               print "Position "; position
               print "Page : "; pageNum
           else if (msg.isScreenClosed()) then
               print "Closed"
               return
           end if
       end if
   end while
End Sub

Sub PrintXML(element As Object, depth As Integer)
    print tab(depth*3);"Name: ";element.GetName()
    if not element.GetAttributes().IsEmpty() then
        print tab(depth*3);"Attributes: ";
        for each a in element.GetAttributes()
            print a;"=";left(element.GetAttributes()[a], 20);
            if element.GetAttributes().IsNext() then print ", ";
        end for
        print
    end if
    if element.GetText()<>invalid then
        print tab(depth*3);"Contains Text: ";left(element.GetText(), 40)
    end if
    if element.GetChildElements()<>invalid
        print tab(depth*3);"Contains roXMLList:"
        for each e in element.GetChildElements()
            PrintXML(e, depth+1)
        end for
    end if
    print
end sub

function getGifFrames(path as String) as Object
    http = CreateObject("roUrlTransfer")
    'test gif, courtesy of r/wheredidthesodago: http://i.imgur.com/yRky4gl.gif
    http.SetUrl("http://gif-explode.com/?explode="+path)
    xml = http.GetToString()
    ' Remove all whitespace/newlines
    rCo = CreateObject("roRegex","\s","s")
    xml = rCo.ReplaceAll(xml,"")
    itemList = CreateObject("roArray", 1, true)
    ' Regex pattern match for finding all base64 strings.
    ' Chr(34) is the brightscript reference to a quotation mark
    strTesting = "gif;base64,.*?" + Chr(34)
    rCo = CreateObject("roRegex",strTesting,"g")
    ' Regex used to find the first instance of this pattern
    ' Can we just use rCo?
    rCo2 = CreateObject("roRegex","gif;base64,","")
    ' Regex match only gives you the first result. So wee need to loop through
    ' and find all possible matches until it doesn't find anything.
    ' I really wish brighscript had a "MatchAll" like most other Regex
    while rCo.Match(xml).Count() = 1
     ' Gets the first base64 path
      gifItem = rCo.Match(xml)[0]
      ' Remove gif;base64,
      gifItem = gifItem.Right(gifItem.Len() - 11)
      ' Remove quotation mark at the end
      gifItem = gifItem.Left(gifItem.Len() - 1)
      ' Add the gif frame to the array of frames
      itemList.push(gifItem)
      ' clear base64 string from memory?
      ' should figure out if this is actually doing anything
      ' potentially, could use the string object and see if its any faster
      gifItem = 0
      ' replace the first occurance of the item, so that the next one is found
      ' when the while-loop runs again
      xml = rCo2.Replace(xml,"")
    end while
    ' clear HTML string from memory?
    xml = 0

    return itemList
end function

' TODO: Should figure out a caching strategy, so that the same
' GIF loaded in quick succession isn't downloaded again.
Sub addGifFrames(itemList as Object, contentArray as Object)
  itemCount = itemList.Count()
  print "Gif Frame Count: "; itemCount

  for i=0 to itemCount-1 step +1
    print "GifNumber: ";i
    ba = CreateObject("roByteArray")
    ba.FromBase64String(itemList[i])
    strName = "tmp:/testgif" + i.ToStr() + ".png"
    print "filename:";strName
    ba.WriteFile(strName)
    bb = CreateObject("roAssociativeArray")
    bb.Url = strName
    contentArray.push(bb)
  end for
end sub

function getJson(feed_url) As Object
  http = CreateObject("roUrlTransfer")
  print "GetJson: ";feed_url
  http.SetUrl(feed_url)

  jsonAsString = http.GetToString()

  json = ParseJSON(jsonAsString)

  return json

end function

Sub loadGif(urls)
  canvas = CreateObject("roImageCanvas")
  portLoading = CreateObject("roMessagePort")
  canvas.SetMessagePort(portLoading)
  items = []
  items.Push({
      Text: "Loading gif"
      TextAttrs: { font: "large", color: "#a0a0a0" }
      TargetRect: {x: 200, y: 75, w: 300, h: 200}
  })
  canvas.SetLayer(0, { Color: "#ff000000", CompositionMode: "Source" })
  canvas.SetLayer(1, items)
  canvas.Show()

  streams = []
  rFixUrl = CreateObject("roRegex", "\\", "i")
  for each url in urls
    resultObj = getJson("http://upload.gfycat.com/transcode?fetchUrl="+url)
    newUrl = rFixUrl.ReplaceAll(resultObj.mp4Url,"")
    print "newUrl"; newUrl
    streams.push({
      url: newUrl,
      quality : false,
      contentid : resultObj.gfyname
    })
  end for

  canvas.Close()
  showGifScreen({Streams:streams})

end sub

Sub ShowImageScreen(post)
  port = CreateObject("roMessagePort")
	slideshow = CreateObject("roSlideShow")
	slideshow.SetMessagePort(port)
	slideshow.SetUnderscan(5.0)      ' shrink pictures by 5% to show a little bit of border (no overscan)
	slideshow.SetBorderColor("#333333")
	slideshow.SetMaxUpscale(8.0)
	slideshow.SetDisplayMode("scale-to-fit")
	slideshow.SetPeriod(6)
	'slideshow.Pause()

	contentArray = CreateObject("roArray", 1, true)
  singleItem = true
  isNotGif = true
	url = post.url

	if url<>invalid then
		r = CreateObject("roRegex", "https", "")
		url = r.Replace(url,"http")
    extension = url.Right(3)
    print "domain: ";post.domain

    print "Path extension: ";extension
    if extension = "gif" then
      isNotGif = false
      loadGif([url])

      'addGifFrames(getGifFrames(url), contentArray)

		else if (post.domain = "imgur.com") then
            r2 = CreateObject("roRegex", "imgur.com/a", "i")

            if r2.IsMatch(url) then

              'This is a hacky way of getting the list of images in the album...
              'by finding some random JSON initializer in the HTML source
              connect = CreateObject("roUrlTransfer")
              connect.SetUrl(url)
              alltext = connect.GetToString()
              r36 = CreateObject("roRegex","Imgur.Album.getInstance\((.*?)\);","s")
              alljson = r36.Match(alltext)[1]
              r41 = CreateObject("roRegex","images\s+\:\s+(.*?)\,\s+cover","s")
              neededJson = r41.Match(alljson)[1]
              objOfImages = ParseJSON(neededJson)

              singleItem = false

              gifsArray = []
              for each item in objOfImages.items
                aa = CreateObject("roAssociativeArray")
                aa.Url = "http://i.imgur.com/"+item.hash+item.ext
                if item.ext = ".gif" then
                  gifsArray.push(aa.Url)
                end if
                contentArray.Push(aa)
              end for

              'If there are gifs, then show those instead of images
              if gifsArray.Count() > 0 then
                isNotGif = false
                loadGif(gifsArray)
              end if

            else

        			r1 = CreateObject("roRegex","imgur.com","")
              r3 = CreateObject("roRegex","imgur.com/gallery","")
        			url = r1.Replace(url,"i.imgur.com")
              url = r3.Replace(url,"imgur.com")
        			url = url + ".png"

            end if

		else if (post.domain = "livememe.com") then

			r1 = CreateObject("roRegex","livememe.com","")
			url = r.Replace(url,"i.lvme.me")
			url = url + ".png"

    else if post.domain.Instr("gfycat") > -1 then
      isNotGif = false
      startIndex = url.Instr(".com/")
      print "startIndex: ";startIndex
      folderString = url.Mid(startIndex+5)
      print "folderString: ";folderString
      contentIdString = folderString
      if folderString.Instr(".gif") > -1 then
        folderString = folderString.Mid(0,folderString.Len()-4)+".gif"
      end if
      print "folderString ";folderString
      loadGif(["http://giant.gfycat.com/"+folderString])
		end if

    'If there is only one item, then add it
    if singleItem = true then
        aa = CreateObject("roAssociativeArray")
        aa.Url = url
        contentArray.Push(aa)
    end if

		print "PRELOAD url: ";url
	end if

  if isNotGif then
	 slideshow.SetContentList(contentArray)

	 slideshow.Show()

  	waitformsg:
  	msg = wait(0, port)
  	print "DisplaySlideShow: class of msg: ";type(msg); " type:";msg.gettype()
  	'for each x in msg:print x;"=";msg[x]:next
  	if msg <> invalid then							'invalid is timed-out
  		if type(msg) = "roSlideShowEvent" then
      		if msg.isScreenClosed() then
  	    		return
      		else if msg.isButtonPressed() then
                  print "Menu button pressed: " + Stri(msg.GetIndex())
                  'example button usage during pause:
                  'if msg.GetIndex() = btn_hide slideshow.ClearButtons()
      		else if msg.isPlaybackPosition() then
  	    		onscreenphoto = msg.GetIndex()
  		    	print "slideshow display: " + Stri(msg.GetIndex())
      		else if msg.isRemoteKeyPressed() then
      			print "Button pressed: " + Stri(msg.GetIndex())
      		else if msg.isRequestSucceeded() then
  	    		print "preload succeeded: " + Stri(msg.GetIndex())
      		elseif msg.isRequestFailed() then
      			print "preload failed: " + Stri(msg.GetIndex())
      		elseif msg.isRequestInterrupted() then
      			print "preload interrupted" + Stri(msg.GetIndex())
      		elseif msg.isPaused() then
                  print "paused"
      		elseif msg.isResumed() then
                  print "resumed"
              end if
          end if
  	end if
  	goto waitformsg
  end if
End Sub


