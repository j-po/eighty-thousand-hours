function showLinkedinModal(){var e=$("#linkedin-signup").data("linkedin-signup").toString();$.ajax({type:"GET",url:"/members/show_linkedin_popup",data:"linkedin_signup="+e})}var fireCount_edit_profile=0;$(document).ready(function(){fireCount_edit_profile++,fireCount_edit_profile>1&&$(".flash-modal").find(".modal-body").text().indexOf("Account successfully created")!=-1&&($(".flash-modal").children(".modal-footer").children(".btn").click(showLinkedinModal),$(".modal-backdrop").click(showLinkedinModal))});