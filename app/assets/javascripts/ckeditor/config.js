CKEDITOR.editorConfig = function( config )
{
  config.extraPlugins = 'save-to-pdf';
  config.removeDialogTabs = 'image:Upload;image:Link;image:advanced';
  config.language = 'en';
  config.uiColor = '#ffffff';
  config.pasteFromWordRemoveStyles = false;
  config.filebrowserBrowseUrl = "/ckeditor/attachment_files";
  config.filebrowserFlashBrowseUrl = "/ckeditor/attachment_files";
  config.filebrowserFlashUploadUrl = "/ckeditor/attachment_files";
  config.filebrowserImageBrowseLinkUrl = "/ckeditor/pictures";
  config.filebrowserImageBrowseUrl = "/ckeditor/pictures";
  config.filebrowserImageUploadUrl = "/ckeditor/pictures";
  config.filebrowserUploadUrl = "/ckeditor/attachment_files";
  config.filebrowserUploadMethod  = "form";
  config.allowedContent = true;
};
