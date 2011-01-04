class DeptTourMailer < ActionMailer::Base
  default :from => "deprel@hkn.eecs.berkeley.edu"
  
  def dept_tour_email(name, date, email_address, phone, comments)
    @name = name
    @date = date
    @email_address = email_address
    @phone = phone
    @comments = comments
    mail :to => 'conorh@hkn.eecs.berkeley.edu', :subject => "Department Tour Request on #{date}"
  end
  
  def dept_tour_response_email(dept_tour_request,resp_text,from,addtl_ccs)
    @resp_text = resp_text
    mail :to => dept_tour_request.contact, :subject => "Department Tour Request on #{dept_tour_request.date}",
      :from => from, :cc => [addtl_ccs, "deprel@hkn.eecs.berkeley.edu", from].reduce { |eml,emls| eml + '; ' + emls }
  end
end
