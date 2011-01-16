class CoursePreference < ActiveRecord::Base

  # === List of columns ===
  #   id         : integer 
  #   course_id  : integer 
  #   tutor_id   : integer 
  #   level      : integer 
  #   created_at : datetime 
  #   updated_at : datetime 
  # =======================

  #Level 0 = current, Level 1 = completed, Level 2 = preferred

  belongs_to :course
  belongs_to :tutor

  validates :course, :presence => true
  validates :tutor, :presence => true
  validates :level, :presence => true
  validates_numericality_of :level, :only_integer => true, :message => "can only be whole number."
  validates_inclusion_of :level, :in => 0..2, :message => "invalid value." 

  #For scheduler class view
  def CoursePreference.all_courses
    ret = Hash.new()
    for cpref in CoursePreference.all
      course = cpref.course
      if ret[course.dept_abbr].nil?
        ret[course.dept_abbr] = []
      end
      if not ret[course.dept_abbr].include?(course.full_course_number)
        ret[course.dept_abbr] << course.full_course_number
      end
    end
    return ret
  end

end
