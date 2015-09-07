fs = require 'fs-plus'
_ = require 'lodash'
pathWatcher = require atom.packages.resourcePath + '/node_modules/pathwatcher/lib/main'

imageRegister = {}

MarkdownPreviewView = null # Defer until used
isMarkdownPreviewView = (object) ->
  MarkdownPreviewView ?= require './markdown-preview-view'
  object instanceof MarkdownPreviewView

renderPreviews = _.debounce((->
  for item in atom.workspace.getPaneItems()
    if isMarkdownPreviewView(item)
      item.renderMarkdown()
  return), 250)

srcClosure = (src) ->
  return (event, path) ->
    if event is 'change' and fs.isFileSync(src)
      imageRegister[src].version = Date.now()
    else
      imageRegister[src].version = undefined
    renderPreviews()
    return

module.exports =
  removeFile: (file) ->
    imageRegister = _.mapValues imageRegister, (image) ->
      image.files = _.without image.files, file
      if _.isEmpty image.files
        image.watched = false
        image.watcher.close()
      image

  getVersion: (image, file) ->
    i = _.get(imageRegister, image, {})
    if _.isEmpty(i)
      if fs.isFileSync image
        version = Date.now()
        imageRegister[image] = {
          path: image,
          watched: true,
          files: [file]
          version: version,
          watcher: pathWatcher.watch(image, srcClosure(image))
        }
        return version
      else
        return false

    files = _.get(i, 'files')
    if not _.contains(files, file)
      imageRegister[image].files.push file

    version = _.get(i, 'version')
    if not version and fs.isFileSync image
      version = Date.now()
      imageRegister[image].version = version
    version
